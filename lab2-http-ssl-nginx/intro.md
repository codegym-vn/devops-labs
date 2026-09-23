Chào mừng bạn đến với bài lab **HTTP/HTTPS & SSL/TLS Certificates Cho Nginx**.

Trong hệ sinh thái DevOps hiện đại, **mọi giao tiếp giữa các dịch vụ** (API Gateway, Microservices, CI/CD Webhook, Container Registry) đều đi qua giao thức **HTTP** hoặc **HTTPS**. Hiểu rõ cách một HTTP request được gửi đi, phản hồi trả về như thế nào, và tại sao cần mã hóa bằng TLS là kỹ năng thiết yếu để debug, tối ưu và bảo mật hạ tầng.

---

## Tại Sao DevOps Engineer Cần Hiểu HTTP/HTTPS?

- **Debug lỗi 502 Bad Gateway, 504 Gateway Timeout**: Cần đọc được HTTP status code và headers để xác định lỗi ở tầng nào (Nginx, backend, hay mạng).
- **Cấu hình SSL/TLS cho domain**: Mọi ứng dụng production đều yêu cầu HTTPS. Bạn cần biết cách tạo, cài đặt và gia hạn certificate.
- **SSL Termination tại Reverse Proxy**: Nginx giải mã TLS rồi chuyển tiếp HTTP thuần tới backend, giúp giảm tải và tập trung quản lý certificate.

---

## So Sánh HTTP vs HTTPS

| Đặc Tính | HTTP | HTTPS |
|---|---|---|
| **Cổng mặc định** | 80 | 443 |
| **Mã hóa dữ liệu** | Không — dữ liệu truyền dưới dạng plaintext | Có — mã hóa bằng TLS/SSL |
| **Xác thực server** | Không — không kiểm tra danh tính server | Có — server xuất trình Certificate |
| **Toàn vẹn dữ liệu** | Không đảm bảo — dữ liệu có thể bị sửa đổi giữa đường | Đảm bảo — mọi thay đổi đều bị phát hiện |
| **Ứng dụng** | Môi trường nội bộ, dev/test | Production, API public, mọi hệ thống có dữ liệu nhạy cảm |

---

## Kiến Trúc Tổng Quan Bài Lab

```text
                    Bước 1: HTTP                  Bước 3: HTTPS (TLS)
    Client  ───── Port 80 (plaintext) ─────>  [ Nginx ]
  (curl/browser)                                  │
                ───── Port 443 (encrypted) ──>  [ Nginx + SSL Certificate ]
                                                  │
                    Bước 2: Kiểm tra              (SSL Termination)
                    Certificate thực tế            │
                    bằng openssl s_client          ▼
                                              [ Backend ]
```

---

## Mục Tiêu Bài Học

Sau khi hoàn thành bài thực hành này, bạn sẽ:
1. **Phân tích được luồng HTTP Request/Response** chi tiết bằng `curl -v`: method, status code, headers.
2. **Hiểu cơ chế bắt tay TLS (TLS Handshake)** và tại sao HTTPS bảo vệ dữ liệu trên đường truyền.
3. **Kiểm tra Certificate thực tế** của website bằng `openssl s_client`: Subject, Issuer, ngày hết hạn, certificate chain.
4. **Tạo Self-Signed Certificate** bằng `openssl` cho môi trường dev/test.
5. **Cấu hình Nginx phục vụ HTTPS** trên cổng 443 với SSL/TLS.
6. **Thiết lập HTTP-to-HTTPS Redirect** tự động chuyển hướng traffic từ cổng 80 sang 443.

---

## Tính Năng Tương Tác Trên Killercoda

- **Tự động hóa môi trường (Background Initialization)**: Các công cụ (`nginx`, `openssl`, `curl`) được hệ thống tự động cài đặt ngầm.
- **Thực thi lệnh nhanh**: Bấm trực tiếp vào các khối lệnh code trên hướng dẫn để tự động gửi và chạy lệnh trên terminal.
- **Xác thực tự động (Verify Check)**: Mỗi bước đều có phần **Thử Thách**. Sau khi hoàn thành, hãy bấm nút **Check** để hệ thống tự động chấm điểm.

Bấm **START** hoặc chọn **Bước 1** để bắt đầu!
