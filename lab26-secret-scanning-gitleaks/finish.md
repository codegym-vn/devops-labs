# Hoàn Thành Bài Lab 26: Quét Lỗ Hổng Lộ Bí Mật Với Gitleaks

Xin chúc mừng! Bạn đã hoàn thành xuất sắc bài thực hành phòng chống rò rỉ bí mật và khóa xác thực trong mã nguồn bằng công cụ **Gitleaks**.

---

## 1. Tổng Kết Các Kỹ Năng Đã Đạt Được

1. **Phát Hiện Thông Tin Mật Với Gitleaks CLI:**
   * Hiểu rõ cơ chế kết hợp giữa hàng trăm biểu thức chính quy (Regex) và thuật toán Shannon Entropy để phát hiện khóa bí mật với độ chính xác cao.
   * Sử dụng cờ `--no-git` để kiểm tra nhanh thư mục đang làm việc trước khi đưa vào hệ thống quản lý phiên bản.

2. **Truy Vết Bí Mật Bị Chôn Sâu Trong Lịch Sử Git:**
   * Chứng minh nguyên tắc bảo mật cốt lõi: Xóa file ở commit mới không giải quyết được rò rỉ secret trong lịch sử Git.
   * Truy vết chính xác mã commit, tác giả và thời điểm khóa bị lọt vào kho lưu trữ để kịp thời thu hồi (Revoke/Rotate).

3. **Thiết Lập Vành Đai Phòng Thủ Đầu Tiên (Pre-commit Hook):**
   * Sử dụng lệnh `gitleaks protect --staged` để chặn đứng lập trình viên vô tình commit token ngay tại máy trạm.
   * Tối ưu hóa hiệu năng kiểm tra (chỉ quét các thay đổi trong vùng Staging).

4. **Quản Trị Ngoại Lệ Chuẩn Doanh Nghiệp:**
   * Cấu hình tệp `.gitleaks.toml` để xử lý các token giả lập trong môi trường kiểm thử (Testing/Mocking), tránh hiện tượng báo động giả (False Positive) làm tắc nghẽn quy trình làm việc.

---

## 2. Checklist Xử Lý Khi Vô Tình Lộ Secret Lên Git

Nếu một secret thực tế bị lọt lên GitHub hoặc GitLab, hãy tuân thủ quy trình ứng phó sự cố:

| Bước | Hành động bắt buộc |
|---|---|
| **Bước 1** | **Revoke & Rotate ngay lập tức:** Thu hồi token cũ và tạo token mới trên trang quản trị nhà cung cấp (AWS, GitHub, Stripe...). Đây là bước duy nhất đảm bảo an toàn. |
| **Bước 2** | **Kiểm tra nhật ký truy cập (Audit Logs):** Kiểm tra xem trong khoảng thời gian bị lộ, token đó có bị IP lạ sử dụng hay không. |
| **Bước 3** | **Viết lại lịch sử Git (Rewrite History):** Sử dụng các công cụ chuyên dụng như `git-filter-repo` hoặc BFG Repo-Cleaner để loại bỏ hoàn toàn chuỗi secret khỏi lịch sử Git. |
| **Bước 4** | **Cài đặt Git Hook & CI/CD Gate:** Tích hợp Gitleaks vào quy trình pre-commit và CI pipeline để ngăn chặn sự cố tương tự tái diễn. |

---

Bạn có thể tiếp tục tự do khám phá môi trường hoặc đóng kịch bản bài học. Chúc bạn ứng dụng thành công các kiến thức bảo mật này vào các dự án phần mềm thực tế!
