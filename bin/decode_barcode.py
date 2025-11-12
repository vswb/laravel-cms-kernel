# ========================================
# Tạo môi trường ảo (venv)
# Bạn KHÔNG nên cài trực tiếp vào hệ thống, vì macOS hạn chế cài global.

# - python3 -m venv ~/barcode-env
# - source ~/barcode-env/bin/activate

# ========================================
# Giai đoạn xử lý:
# 1. Quét bằng Pyzbar từ ảnh gốc
# 2. Nếu lỗi → crop → CLAHE + sharpen → decode (pyzbar)
# 3. Nếu lỗi → fallback_enhance_final_attempt (CLAHE, resize, morphology...) → decode (pyzbar)
# 4. Nếu lỗi → **gọi ZXing qua command-line** để thử giải mã
# 5. Cuối cùng: OCR (Tesseract) với filter qua regex

# =========>> A) Sử dụng thư viện: pyzbar + OpenCV: decode barcode, gọi zbar C-lib qua Python
# Các kỹ thuật tối ưu đã áp dụng:
# 1) Chiến lược xử lý 2 bước (Dual-Pass):
#     Lần 1: Dùng ảnh gốc để decode.
#     Lần 2: Nếu thất bại → crop tự động → tăng cường ảnh → thử lại.
# 2) Tăng cường ảnh sau crop:
#     Sử dụng CLAHE (Contrast Limited Adaptive Histogram Equalization) để tăng tương phản cục bộ.
#     Áp dụng sharpening kernel để làm nét ảnh.
# 3) Thuật toán crop barcode tự động:
#     Dựa vào Sobel + Morphology để tìm vùng mã vạch lớn nhất trong ảnh.
# 4) Thử lại với enhance_image nếu crop-enhance vẫn thất bại:
#     Làm nét + threshold bằng Otsu để tăng độ rõ nét.
# 5) Log chi tiết từng ảnh và thống kê cuối cùng:
#     Log từng ảnh trong result.txt và tổng hợp cuối cùng trong results.txt, gồm tỷ lệ %, thời gian xử lý và tổng số lượng.
# 6) Sử dụng temp_path để không ghi đè file gốc.

# =========>> B) Sử dụng thêm thư viện: ZXing: decode barcode (Java-based), xử lý tốt các mã khó, độ nghiêng cao
# ZXing (Zebra Crossing) là thư viện decode barcode độc lập do Google phát triển, hỗ trợ:
# 1D (Code 128, Code 39, EAN, UPC, ITF...)
# 2D (QR Code, Data Matrix, Aztec...)
# ~/zxing/
#   ├── core-3.4.1.jar (https://repo1.maven.org/maven2/com/google/zxing/core/3.4.1/core-3.4.1.jar)
#   ├── javase-3.4.1.jar (https://repo1.maven.org/maven2/com/google/zxing/javase/3.4.1/javase-3.4.1.jar)
#   └── jcommander-1.78.jar (https://repo1.maven.org/maven2/com/beust/jcommander/1.78/jcommander-1.78.jar)
# java -cp "core-3.4.1.jar:javase-3.4.1.jar:jcommander-1.78.jar" com.google.zxing.client.j2se.CommandLineRunner sample.jpg
# Raw result:
# 336900208CFF
# Parsed result:
# 336900208CFF
# Found 2 result points.
#   Point 0: (227.0,390.0)
#   Point 1: (1120.0,390.0)

# =========>> C) Sử dụng thêm thư viện: Tesseract, OCR ký tự (text), Không dùng để đọc barcode, nhưng có thể cho các case sau:
# - Mã vạch bị hư, mất đoạn → không thể decode hoàn chỉnh
# - Có ký tự barcode hiển thị rõ (như text bên dưới mã vạch).
# - Dạng barcode là Code128, Code39 hoặc Interleaved 2 of 5, vốn có thể OCR được từng ký tự.

import numpy as np
import time
import os
import shutil
import cv2
from pyzbar.pyzbar import decode
from PIL import Image
import contextlib
import subprocess
import pytesseract  # OCR engine
import re

# ==== CẤU HÌNH ZXING ====
ZXING_JAR_PATH = "/Users/eugene/zxing"
ZXING_CP = ":".join([
    f"{ZXING_JAR_PATH}/core-3.4.1.jar",
    f"{ZXING_JAR_PATH}/javase-3.4.1.jar",
    f"{ZXING_JAR_PATH}/jcommander-1.78.jar"
])

from pytesseract import image_to_string

def enhance_full_image_contrast(img):
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    clahe = cv2.createCLAHE(clipLimit=2.5, tileGridSize=(8, 8))
    enhanced = clahe.apply(gray)
    kernel = np.array([[0, -1, 0], [-1, 5, -1], [0, -1, 0]])
    sharpened = cv2.filter2D(enhanced, -1, kernel)
    return cv2.cvtColor(sharpened, cv2.COLOR_GRAY2BGR)

def try_small_rotations(image_pil):
    angles = [-15, -10, -5, 5, 10, 15]
    for angle in angles:
        rotated = image_pil.rotate(angle, expand=True)
        barcodes = decode_safe(rotated)
        if barcodes:
            print(f"[SMALL-ROTATE] Thành công với góc {angle}")
            return barcodes
    return []

def real_esrgan_enhance(image_cv):
    """
    Giả lập Real-ESRGAN: resize ảnh gấp đôi để tránh lỗi gọi tool thực tế.
    Giữ ổn định pipeline, không cần cài thêm gì.
    """
    try:
        height, width = image_cv.shape[:2]
        resized = cv2.resize(image_cv, (width * 2, height * 2), interpolation=cv2.INTER_CUBIC)
        print(f"[FAKE-REAL-ESRGAN] Đã resize ảnh từ {width}x{height} → {width*2}x{height*2}")
        return resized
    except Exception as e:
        print(f"[ERROR] Fake Real-ESRGAN failed: {e}")
        return image_cv  # fallback: trả lại ảnh gốc nếu có lỗi

def final_extreme_enhance_for_hard_cases(img):
    """
    Cố gắng cứu ảnh cực khó: CLAHE mạnh + morphology + sharpen gắt + adaptive threshold.
    Chỉ gọi nếu các bước trước đều thất bại.

    - Resize lớn
    - CLAHE clipLimit cao hơn
    - Erode/Dilate mạnh hơn để tách barcode
    - Sharpen kernel mạnh hơn
    """
    resized = cv2.resize(img, None, fx=3.5, fy=3.5, interpolation=cv2.INTER_CUBIC)
    gray = cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY)

    # CLAHE mạnh hơn
    clahe = cv2.createCLAHE(clipLimit=7.0, tileGridSize=(8, 8))
    contrast = clahe.apply(gray)

    # Morphology + Erode/Dilate mạnh hơn
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (7, 3))
    morph = cv2.morphologyEx(contrast, cv2.MORPH_CLOSE, kernel, iterations=2)
    morph = cv2.erode(morph, None, iterations=1)
    morph = cv2.dilate(morph, None, iterations=1)

    # Sharpen gắt
    sharpen_kernel = np.array([[0, -1, 0],
                               [-1, 6, -1],
                               [0, -1, 0]])
    sharpened = cv2.filter2D(morph, -1, sharpen_kernel)

    # Adaptive threshold
    adaptive = cv2.adaptiveThreshold(sharpened, 255, cv2.ADAPTIVE_THRESH_MEAN_C,
                                     cv2.THRESH_BINARY, 15, 5)

    return cv2.cvtColor(adaptive, cv2.COLOR_GRAY2BGR)

def decode_with_ocr(image_path):
    """
    Dùng Tesseract OCR để trích xuất text, lọc và trả về các chuỗi có định dạng giống serial.
    Ưu tiên chuỗi kết thúc bằng hậu tố barcode thực tế như CF, CE, CFF, PK, BF, GF, CR, QK...
    """
    ocr_text = pytesseract.image_to_string(Image.open(image_path))
    print(f"[OCR RAW] {os.path.basename(image_path)} → {repr(ocr_text.strip())}")

    # Làm sạch và chuẩn hóa chuỗi
    text = ocr_text.upper().replace('\n', ' ').replace('\r', ' ').strip()
    text = re.sub(r'[^A-Z0-9]', ' ', text)  # chỉ giữ lại A-Z và số

    # Danh sách hậu tố thường gặp trong barcode thực tế
    valid_suffixes = {
        'CF', 'CE', 'CK', 'GF', 'NF', 'PK', 'BF', 'QK', 'CR',
        'CED', 'CEH', 'CEI', 'CEJ', 'CEM', 'CFF', 'CFK', 'CFA', 'CFD', 'CFC',
        'GFP', 'GF-', 'NF7', 'PKN', 'PKP', 'BFP', 'BFT', 'CKV', 'CKT',
        'CFI', 'CF9', 'CFH', 'CEE', 'CEF'
    }

    # Tìm tất cả chuỗi dạng A-Z + số dài 8–20 ký tự
    candidates = re.findall(r'\b[A-Z0-9]{8,20}\b', text)

    # Ưu tiên các chuỗi có hậu tố trong danh sách
    filtered = [s for s in candidates if any(s.endswith(sfx) for sfx in valid_suffixes)]

    # Nếu không có chuỗi nào thỏa điều kiện → fallback: giữ tất cả candidates
    if not filtered:
        filtered = candidates

    # Loại bỏ trùng lặp
    filtered = list(set(filtered))

    return filtered

# def decode_with_ocr(image_path):
#     """
#     Dùng Tesseract OCR để trích xuất text, lọc và trả về các chuỗi có định dạng giống serial.
#     Ưu tiên không xoá khoảng trắng, để regex có thể tách từ đúng.
#     Cho phép các định dạng barcode thực tế: 8–20 ký tự, chỉ gồm A-Z, 0-9.
#     """
#     ocr_text = pytesseract.image_to_string(Image.open(image_path))
#     print(f"[OCR RAW] {os.path.basename(image_path)} → {repr(ocr_text.strip())}")

#     # Chuẩn hóa văn bản: viết hoa, xoá ký tự đặc biệt nhưng giữ khoảng trắng
#     text = ocr_text.upper().replace('\r', ' ').replace('\n', ' ').strip()
#     text = re.sub(r'[^A-Z0-9 ]', ' ', text)  # chỉ giữ A-Z, 0-9 và khoảng trắng

#     # Regex: lấy tất cả chuỗi A-Z0-9 dài từ 8 đến 20 ký tự, dựa vào biên từ \b
#     matches = re.findall(r'\b[A-Z0-9]{8,20}\b', text)

#     # Loại bỏ trùng lặp và sắp xếp
#     matches = sorted(set(matches))
#     return matches


def decode_with_zxing(image_path):
    """
    Gọi ZXing qua command-line để giải mã barcode nếu các bước trước thất bại.
    Trả về danh sách string barcode, hoặc rỗng nếu không thành công.
    """
    try:
        result = subprocess.run(
            ["java", "-cp", ZXING_CP, "com.google.zxing.client.j2se.CommandLineRunner", image_path],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=5
        )
        if "Parsed result:" in result.stdout:
            for line in result.stdout.splitlines():
                if line.startswith("Parsed result:"):
                    return [line.replace("Parsed result:", "").strip()]
        return []
    except Exception as e:
        print(f"[ZXING ERROR] {e}")
        return []

def decode_safe(pil_img):
    """
    Giải mã barcode bằng pyzbar, đồng thời ẩn cảnh báo stderr nếu có lỗi ZBar.
    """
    with contextlib.redirect_stderr(open(os.devnull, 'w')):
        return decode(pil_img)

# ==== BƯỚC 1: TĂNG CƯỜNG ẢNH ====
def enhance_contrast_and_sharpness(img):
    """
    Tăng tương phản bằng CLAHE và làm nét ảnh (áp dụng sau khi crop).
    """
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
    enhanced = clahe.apply(gray)

    # Kernel làm nét nhẹ
    kernel = np.array([[0, -1, 0],
                       [-1, 5, -1],
                       [0, -1, 0]])
    sharpened = cv2.filter2D(enhanced, -1, kernel)
    return sharpened

def enhance_image(img):
    """
    Làm nét ảnh mạnh hơn (dùng làm bước fallback thứ hai).
    Bổ sung thêm bước unsharp mask và resize lớn hơn để cải thiện nhận diện.
    """
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # === THÊM: Resize lớn hơn để xử lý chi tiết mờ
    resized = cv2.resize(gray, None, fx=3, fy=3, interpolation=cv2.INTER_CUBIC)

    # === THÊM: Unsharp mask thay vì làm nét đơn giản
    blurred = cv2.GaussianBlur(resized, (9, 9), 10.0)
    unsharp = cv2.addWeighted(resized, 1.5, blurred, -0.5, 0)

    # Khử nhiễu sau khi sharpen
    denoised = cv2.fastNlMeansDenoising(unsharp, None, h=15, templateWindowSize=7, searchWindowSize=21)

    _, thresh = cv2.threshold(denoised, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    return cv2.cvtColor(thresh, cv2.COLOR_GRAY2BGR)

def fallback_enhance_final_attempt(img):
    """
    Bước cuối: resize lớn lên, CLAHE mạnh hơn, làm nét + adaptive threshold.
    Thử nghiệm thêm các phương pháp threshold khác để cứu các ảnh khó.
    """
    resized = cv2.resize(img, None, fx=2, fy=2, interpolation=cv2.INTER_CUBIC)
    gray = cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY)
    clahe = cv2.createCLAHE(clipLimit=5.0, tileGridSize=(8, 8))
    contrast = clahe.apply(gray)

    kernel = np.array([[0, -1, 0],
                       [-1, 5, -1],
                       [0, -1, 0]])
    sharpened = cv2.filter2D(contrast, -1, kernel)

    # === THỬ: Adaptive threshold Gaussian thay vì MEAN
    adaptive_thresh = cv2.adaptiveThreshold(sharpened, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                                            cv2.THRESH_BINARY, 15, 10)

    # === THỬ: Threshold TRIANGLE thêm lựa chọn
    _, triangle_thresh = cv2.threshold(sharpened, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_TRIANGLE)

    # === TRẢ VỀ: thử adaptive trước, fallback triangle nếu adaptive cho kết quả xấu
    # (Tùy vào testing thực tế để bạn chọn thứ tự)

    # Convert về ảnh màu
    return cv2.cvtColor(adaptive_thresh, cv2.COLOR_GRAY2BGR)

# ==== BƯỚC 2: TÌM VÙNG MÃ VẠCH ====
def auto_crop_barcode(image_cv):
    """
    Phát hiện vùng có khả năng chứa mã vạch dựa trên Sobel + morphology.
    Bổ sung thêm lựa chọn kernel morphology khác để xử lý các barcode hẹp/nghiêng.
    """
    gray = cv2.cvtColor(image_cv, cv2.COLOR_BGR2GRAY)
    grad = cv2.Sobel(gray, ddepth=cv2.CV_32F, dx=1, dy=0, ksize=-1)
    grad = cv2.convertScaleAbs(grad)

    # Lọc các vùng có gradient mạnh
    _, thresh = cv2.threshold(grad, 225, 255, cv2.THRESH_BINARY)
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (25, 5))
    closed = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel)
    closed = cv2.erode(closed, None, iterations=4)
    closed = cv2.dilate(closed, None, iterations=4)

    # === THÊM: Thử kernel morphology hẹp hơn, để bắt các mã vạch mảnh hoặc lệch ===
    kernel_alt = cv2.getStructuringElement(cv2.MORPH_RECT, (15, 3))
    closed_alt = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel_alt)
    closed_alt = cv2.erode(closed_alt, None, iterations=2)
    closed_alt = cv2.dilate(closed_alt, None, iterations=2)

    # So sánh số contour, chọn bản tốt hơn
    contours, _ = cv2.findContours(closed.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    contours_alt, _ = cv2.findContours(closed_alt.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    best_contours = contours_alt if len(contours_alt) > len(contours) else contours

    if not best_contours:
        return None

    c = max(best_contours, key=cv2.contourArea)
    x, y, w, h = cv2.boundingRect(c)
    return image_cv[y:y + h, x:x + w]

# ==== BƯỚC 3: XỬ LÝ ẢNH ĐƠN LẺ ====
def process_image(image_path):
    """
    Xử lý từng ảnh:
    - Dùng pyzbar decode ảnh gốc
    - Nếu lỗi → auto crop barcode → CLAHE + sharpen → decode
    - Nếu vẫn lỗi → enhance mạnh hơn → decode lại
    - Nếu vẫn lỗi → thử xoay các góc (90,180,270)
    - Nếu vẫn lỗi → Real-ESRGAN (ảnh khó)
    - Nếu vẫn lỗi → Full image enhance + small angle rotation
    - Nếu vẫn lỗi → ZXing (Java)
    - Nếu vẫn lỗi → OCR
    - Nếu vẫn lỗi → đánh dấu ảnh không thông tin

    Trả về:
        - barcodes: danh sách kết quả barcode
        - method: công cụ decode dùng (pyzbar, zxing, ocr)
        - reason: lý do thành công/thất bại (phân loại lỗi)
        - info_level: mức độ thông tin tồn tại trong ảnh (full_info, text_only, no_info)
    """
    def try_decode_with_rotation(pil_img, angle_list=[90, 180, 270]):
        """
        Thử xoay ảnh ở các góc và decode lại.
        """
        for angle in angle_list:
            rotated = pil_img.rotate(angle, expand=True)
            barcodes = decode_safe(rotated)
            if barcodes:
                print(f"[ROTATE-DECODE] Thành công với góc {angle}")
                return barcodes
        return []

    try:
        # 1. Pyzbar từ ảnh gốc
        image_pil = Image.open(image_path)
        barcodes = decode_safe(image_pil)
        if barcodes:
            # Fallback OCR nếu decode ra barcode nhưng data rỗng
            if all(not b.data.strip() for b in barcodes):
                print(f"[EMPTY-BARCODE] Không có nội dung barcode, fallback OCR: {image_path}")
                ocr_result = decode_with_ocr(image_path)
                if ocr_result:
                    class DummyBarcode:
                        def __init__(self, data): self.data = data.encode('utf-8')
                    return [DummyBarcode(data) for data in ocr_result], "ocr_fallback", "empty_barcode_fallback", "text_only"
                return barcodes, "pyzbar", "empty_barcode_failed_ocr", "no_info"
            return barcodes, "pyzbar", "success", "full_info"

        # 2. Auto crop → CLAHE + sharpen
        image_cv = cv2.imread(image_path)
        cropped = auto_crop_barcode(image_cv)
        if cropped is not None:
            enhanced = enhance_contrast_and_sharpness(cropped)
            temp_path = image_path + ".temp.jpg"
            cv2.imwrite(temp_path, enhanced)
            image_pil_cropped = Image.open(temp_path)
            barcodes = decode_safe(image_pil_cropped)
            os.remove(temp_path)
            if barcodes:
                return barcodes, "pyzbar", "success", "full_info"

            # 🌀 THỬ XOAY ẢNH ĐÃ ENHANCE
            barcodes = try_decode_with_rotation(image_pil_cropped)
            if barcodes:
                return barcodes, "pyzbar_rotated", "rotated_success_after_crop", "full_info"

            # 3. Fallback enhance mạnh hơn (resize, sharpen, morphology)
            enhanced = enhance_image(cropped)
            temp_path = image_path + ".enhanced.jpg"
            cv2.imwrite(temp_path, enhanced)
            image_pil_fallback = Image.open(temp_path)
            barcodes = decode_safe(image_pil_fallback)
            os.remove(temp_path)
            if barcodes:
                return barcodes, "pyzbar", "success", "full_info"

            # 🌀 THỬ XOAY ảnh fallback
            barcodes = try_decode_with_rotation(image_pil_fallback)
            if barcodes:
                return barcodes, "pyzbar_rotated", "rotated_success_after_fallback", "full_info"

        # === THỬ CUỐI: Real-ESRGAN (tuỳ chọn): chỉ áp dụng cho ảnh khó
        if os.path.basename(image_path).startswith(("z50", "quá_khó")):
            sr_path = image_path + ".sr.jpg"
            if not os.path.exists(sr_path):
                restored = real_esrgan_enhance(image_cv)
                cv2.imwrite(sr_path, restored)
            try:
                image_pil_sr = Image.open(sr_path)
                barcodes = decode_safe(image_pil_sr)
                os.remove(sr_path)
            except Exception as e:
                print(f"[ERROR] Không thể đọc hoặc xóa ảnh SR: {e}")
                barcodes = []

            if barcodes:
                return barcodes, "pyzbar_superres", "success_with_superres", "full_info"

            # 🌀 THỬ XOAY ảnh đã siêu phân giải
            barcodes = try_decode_with_rotation(image_pil_sr)
            if barcodes:
                return barcodes, "pyzbar_superres_rotated", "rotated_success_after_superres", "full_info"

        # === BỔ SUNG: Fallback cuối cùng với full-image enhancement và các góc xoay nhỏ
        full_enhanced = final_extreme_enhance_for_hard_cases(image_cv)
        temp_path = image_path + ".fullenh.jpg"
        cv2.imwrite(temp_path, full_enhanced)
        image_pil_fullenh = Image.open(temp_path)
        barcodes = decode_safe(image_pil_fullenh)
        if barcodes:
            os.remove(temp_path)
            return barcodes, "pyzbar_fullenh", "success_with_fullenhance", "full_info"

        # 🌀 Thử xoay các góc nhỏ (±3°, ±5°, ±7°, 10°)
        for angle in [-10, -7, -5, -3, 3, 5, 7, 10]:
            rotated = image_pil_fullenh.rotate(angle, expand=True)
            barcodes = decode_safe(rotated)
            if barcodes:
                os.remove(temp_path)
                print(f"[SMALL-ROTATE] Thành công với góc {angle}")
                return barcodes, "pyzbar_fullenh_rotated", f"rotated_{angle}_after_fullenhance", "full_info"
        os.remove(temp_path)

        # === ZXing: gọi Java decode
        zxing_result = decode_with_zxing(image_path)
        if zxing_result:
            class DummyBarcode:
                def __init__(self, data): self.data = data.encode('utf-8')
            return [DummyBarcode(data) for data in zxing_result], "zxing", "success", "full_info"

        # === Cuối cùng: OCR nếu không tìm thấy barcode
        ocr_result = decode_with_ocr(image_path)
        if ocr_result:
            class DummyBarcode:
                def __init__(self, data): self.data = data.encode('utf-8')
            return [DummyBarcode(data) for data in ocr_result], "ocr", "barcode_missing_ocr_success", "text_only"

        return [], None, "no_barcode_or_text", "no_info"

    except Exception as e:
        print(f"[ERROR] Lỗi đọc ảnh {image_path}: {e}")
        return [], None, "exception_error", "no_info"

# ==== BƯỚC 4: XỬ LÝ CẢ THƯ MỤC ====
def process_folder(base_dir):
    """
    Xử lý toàn bộ thư mục chứa nhiều sub-folder:
    - Log chi tiết kết quả từng ảnh vào file result.txt trong từng thư mục
    - Ghi tổng hợp vào results.txt ở thư mục gốc
    - Ghi lại ảnh lỗi + lý do vào failed_images.txt
    - Ghi thống kê lỗi theo loại vào error_stats.json
    - Ghi phân loại mức độ thông tin vào info_levels.json
    """
    import json
    start_time = time.time()
    total_ok = 0
    total_nok = 0
    total_pyzbar = 0
    total_zxing = 0
    total_ocr = 0

    error_stats = {}  # Ghi lại số lượng lỗi theo loại: {'no_barcode_found': 12, 'ocr_fail': 4, ...}
    failed_log_path = os.path.join(base_dir, 'failed_images.txt')  # Log từng file bị lỗi + lý do
    failed_log = open(failed_log_path, 'w', encoding='utf-8')

    summary_log_path = os.path.join(base_dir, 'results.txt')
    with open(summary_log_path, 'w', encoding='utf-8') as summary_log:
        for folder_name in os.listdir(base_dir):
            folder_path = os.path.join(base_dir, folder_name)
            if not os.path.isdir(folder_path):
                continue

            print(f"\n📁 Đang xử lý thư mục: {folder_name}")
            ok_dir = os.path.join(folder_path, 'ok')
            os.makedirs(ok_dir, exist_ok=True)
            log_path = os.path.join(folder_path, 'result.txt')

            with open(log_path, 'w', encoding='utf-8') as local_log:
                for file in os.listdir(folder_path):
                    if file.lower().endswith(('.jpg', '.jpeg', '.png')):
                        file_path = os.path.join(folder_path, file)

                        # ⏱ Gọi process_image mới (trả về barcode, method, reason, info_level)
                        barcodes, method, reason, info_level = process_image(file_path)

                        if barcodes:
                            decoded_data = ", ".join([b.data.decode('utf-8') for b in barcodes])
                            log_line = f"{file} → OK | {decoded_data}"
                            shutil.move(file_path, os.path.join(ok_dir, file))
                            total_ok += 1
                            if method == "pyzbar":
                                total_pyzbar += 1
                            elif method == "zxing":
                                total_zxing += 1
                            elif method == "ocr":
                                total_ocr += 1
                        else:
                            log_line = f"{file} → NOK | reason={reason}, info={info_level}"
                            total_nok += 1

                            # Ghi log lỗi chi tiết
                            failed_log.write(f"{folder_name}/{file} → {reason} | info={info_level}\n")
                            error_stats[reason] = error_stats.get(reason, 0) + 1

                        print(log_line)
                        local_log.write(log_line + "\n")
                        summary_log.write(f"{folder_name}/{log_line}\n")

        # Tổng kết
        total = total_ok + total_nok
        percent_ok = round((total_ok / total) * 100, 2)
        percent_nok = round((total_nok / total) * 100, 2)
        elapsed = round(time.time() - start_time, 2)

        summary_log.write("\n")
        summary_log.write(f"Thành công: {total_ok} hình, chiếm {percent_ok}%\n")
        summary_log.write(f"Lỗi: {total_nok} hình, chiếm {percent_nok}%\n")
        summary_log.write(f"Tổng thời gian xử lý: {elapsed} giây\n")
        summary_log.write(f"=== Tổng cộng: {total} hình\n")
        summary_log.write(f"Trong đó: pyzbar = {total_pyzbar}, zxing = {total_zxing}, ocr = {total_ocr}\n")

    failed_log.close()

    # === GHI FILE error_stats.json ===
    stats_path = os.path.join(base_dir, 'error_stats.json')
    with open(stats_path, 'w', encoding='utf-8') as f:
        json.dump(error_stats, f, indent=2, ensure_ascii=False)

    # === GHI FILE info_levels.json (tùy chọn để lọc ảnh theo mức độ dữ liệu) ===
    info_stats = {"full_info": 0, "text_only": 0, "no_info": 0}
    for reason, count in error_stats.items():
        if "text_only" in reason:
            info_stats["text_only"] += count
        elif "no_info" in reason or reason == "no_barcode_or_text":
            info_stats["no_info"] += count
        else:
            info_stats["full_info"] += count

    info_path = os.path.join(base_dir, 'info_levels.json')
    with open(info_path, 'w', encoding='utf-8') as f:
        json.dump(info_stats, f, indent=2, ensure_ascii=False)

# ==== THƯ MỤC GỐC ====
ROOT_PATH = '/Users/eugene/Sites/barcodes/input'
process_folder(ROOT_PATH)