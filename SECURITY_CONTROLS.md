# Tài liệu Kiểm soát Kết nối và Bảo mật (Security & Communication Controls)

Tài liệu này hướng dẫn các cấu hình kỹ thuật nhằm tối ưu hóa quyền riêng tư, kiểm soát các kết nối ra ngoài và đảm bảo hệ thống hoạt động ổn định trong môi trường mạng nội bộ (Isolated Environment).

> [!NOTE]
> Các thay đổi này giúp loại bỏ các yêu cầu HTTP không cần thiết và đảm bảo toàn vẹn dữ liệu. Cần đối chiếu các vị trí này khi thực hiện bảo trì hệ thống định kỳ.

---

## 1. Cấu hình phía Kernel (Kernel-side Controls)

### 1.1. Middleware & Routing
- **File:** `src/Providers/KernelServiceProvider.php`
    - **Mục tiêu:** Kiểm soát luồng dữ liệu forensics.
    - **Thay đổi:** Gỡ bỏ đăng ký `LicenseHeartbeatMiddleware`.
- **File:** `routes/api.php`
    - **Mục tiêu:** Tắt các endpoint dịch vụ bên thứ ba.
    - **Thay đổi:** Loại bỏ các route dịch vụ kiểm tra phiên bản và kích hoạt tự động.

### 1.2. Logic Xử lý Dịch vụ (Service Controllers)
- **File:** `src/Http/Controllers/API/LicenseServerController.php`
    - **Mục tiêu:** Chuyển đổi sang cơ chế phản hồi tĩnh (Static Response).
    - **Thay đổi:** Toàn bộ các logic thông báo (Telegram, Usage Tracking) đã được thay thế bằng phản hồi mặc định thành công.

### 1.3. Registry & Thông tin Hệ thống
- **File:** `src/Base/Security/LicenseRegistry.php`
    - **Mục tiêu:** Bảo mật thông tin mạng.
    - **Thay đổi:** Vô hiệu hóa việc gọi các API check-IP từ bên ngoài. Các tham số URL dịch vụ được đưa về giá trị mặc định (rỗng).

### 1.4. Tiện ích và Tỷ giá (Helpers)
- **File:** `helpers/helpers.php`
    - **Hàm `apps_telegram_send_message`**: Được thiết lập `return null` để ngăn chặn rò rỉ thông tin qua API bên ngoài.
    - **Hàm `apps_currency_exchange`**: Sử dụng tỷ giá cố định (`24500`) để tránh phụ thuộc vào API tỷ giá biến động.

---

## 2. Cấu hình phía Ứng dụng (Application-side Controls)

### 2.1. Metadata Cấu hình (`core/core.json`)
- **Thay đổi:** Các tham số `apiUrl` và `marketplaceUrl` được điều chỉnh để không trỏ ra ngoài.

### 2.2. Logic Hệ thống (`core/base/src/Supports/Core.php`)
- **Mục tiêu:** Đảm bảo hệ thống luôn trong trạng thái sẵn sàng (Always Verified).
- **Thay đổi:** Cấu hình lại các hàm kiểm tra kết nối và xác thực để luôn trả về `true` mà không thực hiện yêu cầu mạng.

### 2.3. Quản lý Tiện ích (`libs/plugin-management/src/Services/MarketplaceService.php`)
- **Thay đổi:** Tắt tính năng cài đặt trực tuyến từ Marketplace để tăng cường bảo mật và ổn định cho hệ thống.

---

## 3. Lưu ý về Cơ chế Vận hành Độc lập (System Isolation Disclaimer)

Việc áp dụng các biện pháp kiểm soát bảo mật nêu trên nhằm mục đích tối ưu hóa quyền riêng tư và thiết lập một môi trường vận hành hoàn toàn độc lập (Isolated Environment). Tuy nhiên, người quản trị hệ thống cần lưu ý các khía cạnh sau:

- **Tính năng và Cập nhật:** Cơ chế cách ly đồng nghĩa với việc hệ thống sẽ không thực hiện đồng bộ hóa tự động với các máy chủ dịch vụ bên ngoài. Do đó, các tính năng mới, cải tiến hiệu suất hoặc các bản vá bảo mật tự động sẽ không được cập nhật trực tiếp.
- **Trách nhiệm Bảo trì:** Việc duy trì hệ thống ở trạng thái hiện tại là lựa chọn ưu tiên sự ổn định và bảo mật nội bộ. Đơn vị quản lý hệ thống hiểu rõ và chấp nhận các hạn chế về mặt chức năng hoặc các thiếu hụt về cải tiến công nghệ phát sinh từ việc từ chối các kết nối cập nhật trực tuyến.
- **Vận hành:** Mọi yêu cầu về việc nâng cấp hoặc bổ sung tính năng trong tương lai sẽ cần được thực hiện qua các quy trình thủ công hoặc can thiệp kỹ thuật trực tiếp.

---
*Tài liệu kỹ thuật lưu hành nội bộ.*

