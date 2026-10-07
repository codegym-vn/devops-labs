# Bước 1: Khám Phá Mã Nguồn & Phát Hiện Lộ Secret Với Gitleaks CLI

Trong bước đầu tiên, bạn sẽ làm quen với kho mã nguồn mẫu, tìm hiểu các file đang bị lộ mật khẩu và sử dụng Gitleaks CLI ở chế độ phân tích thư mục làm việc (Directory Scanning).

---

## 1. Khám Phá Kho Mã Nguồn

Di chuyển vào thư mục làm việc:

```bash
cd /root/secret-leak-lab
ls -la
```{{exec}}

Kiểm tra nội dung tệp `config.json`:

```bash
cat config.json
```{{exec}}

Bạn sẽ thấy một cặp khóa AWS Access Key và Secret Access Key đang bị hardcode trực tiếp trong tệp cấu hình.

Kiểm tra nội dung tệp `database.js`:

```bash
cat database.js
```{{exec}}

Chuỗi kết nối PostgreSQL chứa mật khẩu quản trị nhạy cảm `admin_user:P@ssw0rdSecure2026!` được viết thẳng vào mã nguồn ứng dụng.

---

## 2. Quét Toàn Bộ Thư Mục Với Gitleaks

Lệnh `gitleaks detect --no-git` cho phép quét trực tiếp cây thư mục tệp tin hiện tại (Working Tree) mà không phân tích lịch sử Git commit, rất thích hợp để kiểm tra nhanh:

```bash
gitleaks detect --no-git --source . -v
```{{exec}}

Giải thích các trường thông tin trong kết quả của Gitleaks:
* **RuleID:** Định danh quy tắc phát hiện vi phạm (ví dụ `aws-access-token`, `generic-api-key`).
* **Secret:** Chuỗi ký tự bí mật bị phát hiện trong mã nguồn.
* **File:** Tệp tin và dòng xảy ra sự cố rò rỉ.
* **Entropy:** Độ hỗn loạn của chuỗi ký tự, giúp thuật toán phân biệt giữa chuỗi ngẫu nhiên (token thật) và chuỗi chữ thông thường.

---

## 3. Xuất Báo Cáo Phát Hiện Định Dạng JSON

Để phục vụ lưu trữ kiểm toán hoặc tích hợp vào hệ thống SIEM/SOC, xuất kết quả quét ra tệp JSON:

```bash
gitleaks detect --no-git --source . --report-path gitleaks-uncommitted.json
```{{exec}}

Kiểm tra nội dung báo cáo:

```bash
cat gitleaks-uncommitted.json | grep -E "RuleID|Secret" | head -n 8
```{{exec}}

Nhấn **Check** để hoàn thành Bước 1!
