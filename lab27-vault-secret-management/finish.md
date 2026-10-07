# Hoàn Thành Bài Lab 27: Quản Trị & Inject Secret Với HashiCorp Vault

Xin chúc mừng! Bạn đã hoàn thành xuất sắc bài thực hành quản trị và inject thông tin mật an toàn vào ứng dụng bằng nền tảng **HashiCorp Vault**.

---

## 1. Tổng Kết Các Kỹ Năng Đã Đạt Được

1. **Quản Lý Secret Tập Trung Với KV-v2:**
   * Hiểu rõ cơ chế mã hóa at-rest của Vault và tính năng quản lý lịch sử phiên bản bí mật (Secret Versioning).
   * Thực hiện quy trình đổi mật khẩu định kỳ (Password Rotation) mà không làm gián đoạn hệ thống.

2. **Thiết Lập Phân Quyền Theo Nguyên Tắc Least Privilege:**
   * Viết Vault Policy bằng HCL giới hạn quyền hạn đọc/ghi theo từng tiền tố đường dẫn (`path "secret/data/..."`).
   * Ngăn chặn hoàn toàn việc dịch vụ này xâm phạm hoặc đọc lén secret của dịch vụ khác.

3. **Cơ Chế Xác Thực Máy - Máy (AppRole Authentication):**
   * Sử dụng cặp khóa `RoleID` và `SecretID` để cấp quyền cho CI/CD Runner và máy chủ dịch vụ.
   * Cấp phát Client Token có thời hạn sống ngắn hạn (TTL), tự hủy khi hết hạn.

4. **Kỹ Thuật Inject Secret Không Để Lại Dấu Vết (In-Memory Injection):**
   * Nạp mật khẩu trực tiếp từ Vault REST API vào biến môi trường trong bộ nhớ RAM của tiến trình.
   * Xóa bỏ hoàn toàn việc lưu trữ file `.env` hay tệp cấu hình tĩnh chứa mật khẩu trên đĩa cứng.

---

## 2. So Sánh Các Giải Pháp Quản Lý Secret Phổ Biến

| Tiêu chí | File `.env` phẳng | GitHub Secrets | AWS Secrets Manager | HashiCorp Vault |
|---|---|---|---|---|
| **Mã hóa tập trung** | Không (Plaintext) | Có | Có | **Có (AES-256-GCM)** |
| **Phạm vi sử dụng** | Chỉ cục bộ | Chỉ trong GitHub Actions | Chỉ trong hệ sinh thái AWS | **Đa nền tảng (Any Cloud / On-prem)** |
| **Quản lý phiên bản (Versioning)** | Không | Không | Có | **Có (KV-v2 Engine)** |
| **Cơ chế xác thực máy móc** | Không có | Dùng Token GitHub | IAM Roles / AssumeRole | **AppRole, K8s ServiceAccount, OIDC** |
| **Chi phí triển khai** | Miễn phí | Miễn phí | Tính phí theo secret/API | **Mã nguồn mở miễn phí (Open-Source)** |

---

Bạn có thể tiếp tục tự do khám phá môi trường hoặc đóng kịch bản bài học. Chúc bạn ứng dụng thành công mô hình quản trị an ninh bí mật chuẩn mực này vào các hệ thống Production thực tế!
