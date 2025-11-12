# === OCR TEST TOOL ===
# Cho phép bạn test nhanh ảnh đơn, với các tùy chọn bật/tắt từng bước xử lý

import cv2
import numpy as np
import os
from PIL import Image
import pytesseract
import re
from pyzbar.pyzbar import decode

def decode_barcode_from_image(image_path, debug=True):
    # Load ảnh
    image_cv = cv2.imread(image_path)
    if image_cv is None:
        print(f"❌ Không đọc được ảnh: {image_path}")
        return []

    # 1. Convert sang grayscale
    gray = cv2.cvtColor(image_cv, cv2.COLOR_BGR2GRAY)
    h, w = gray.shape

    # 2. Crop cứng vùng barcode (đã kiểm nghiệm từ ảnh của bạn)
    cropped = gray[int(h * 0.48):int(h * 0.75), int(w * 0.15):int(w * 0.85)]

    # 3. Tăng tương phản nhẹ (CLAHE)
    clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
    contrast = clahe.apply(cropped)

    # 4. Sharpen nhẹ
    sharpened = cv2.filter2D(contrast, -1, np.array([[0, -1, 0], [-1, 5, -1], [0, -1, 0]]))

    if debug:
        os.makedirs("debug", exist_ok=True)
        cv2.imwrite("debug/cropped.jpg", cropped)
        cv2.imwrite("debug/contrast.jpg", contrast)
        cv2.imwrite("debug/sharpened.jpg", sharpened)

    # 5. Giải mã barcode
    results = decode(sharpened)
    if results:
        decoded = [r.data.decode("utf-8") for r in results]
        print(f"✅ Giải mã được: {decoded}")
        return decoded

    print("⚠️ Không giải mã được barcode.")
    return []

def test_ocr_pipeline(image_path, output_dir="debug_ocr",
                      use_denoise=True, upscale_factor=2.0,
                      clahe_clip=5.0, thresh_blocksize=15, thresh_C=5):
    os.makedirs(output_dir, exist_ok=True)
    basename = os.path.splitext(os.path.basename(image_path))[0]

    image_cv = cv2.imread(image_path)
    gray = cv2.cvtColor(image_cv, cv2.COLOR_BGR2GRAY)
    cv2.imwrite(f"{output_dir}/{basename}_1_gray.jpg", gray)

    if use_denoise:
        gray = cv2.fastNlMeansDenoising(gray, None, h=30, templateWindowSize=7, searchWindowSize=21)
        cv2.imwrite(f"{output_dir}/{basename}_2_denoised.jpg", gray)

    resized = cv2.resize(gray, None, fx=upscale_factor, fy=upscale_factor, interpolation=cv2.INTER_CUBIC)
    cv2.imwrite(f"{output_dir}/{basename}_3_resized.jpg", resized)

    clahe = cv2.createCLAHE(clipLimit=clahe_clip, tileGridSize=(8, 8))
    contrast = clahe.apply(resized)
    cv2.imwrite(f"{output_dir}/{basename}_4_clahe.jpg", contrast)

    kernel = np.array([[0, -1, 0], [-1, 5, -1], [0, -1, 0]])
    sharpened = cv2.filter2D(contrast, -1, kernel)
    cv2.imwrite(f"{output_dir}/{basename}_5_sharpened.jpg", sharpened)

    final = cv2.adaptiveThreshold(sharpened, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                                  cv2.THRESH_BINARY, thresh_blocksize, thresh_C)
    cv2.imwrite(f"{output_dir}/{basename}_6_final.jpg", final)

    pil_img = Image.fromarray(final)
    config = '--psm 6 --oem 1 -c tessedit_char_whitelist=0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    ocr_text = pytesseract.image_to_string(pil_img, config=config)
    print(f"[OCR RAW] {basename} =>\n{ocr_text}")

    # Gợi ý regex
    flat = ocr_text.replace('\n', '').upper()
    matches = re.findall(r'1\d{8}(CF|CE)', flat)
    matches += re.findall(r'[A-Z0-9]{6,}(CF|CE)', flat)
    matches += re.findall(r'\b[A-Z0-9]{8,20}\b', ocr_text.upper())
    matches = list(set(matches))
    matches = sorted(matches, key=lambda x: x.endswith(('CF', 'CE')), reverse=True)

    print("[MATCHES]", matches)
    return matches

# === USAGE EXAMPLE ===
test_ocr_pipeline("/Users/eugene/Sites/barcodes/sample2.jpg")
decode_barcode_from_image("/Users/eugene/Sites/barcodes/sample2.jpg")