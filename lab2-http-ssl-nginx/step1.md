# Bước 1: Phân Tích Giao Thức HTTP - Request, Response & Headers

Giao thức **HTTP (HyperText Transfer Protocol)** là nền tảng giao tiếp của World Wide Web và cũng là giao thức chính mà các API, Webhook, Container Registry sử dụng trong hệ thống DevOps. Trước khi hiểu HTTPS, bạn cần nắm vững cách HTTP hoạt động.

> **Lưu ý môi trường:** Hệ thống Killercoda đã tự động cài đặt sẵn `nginx`, `openssl` và `curl` ở chế độ nền. Bạn có thể bắt đầu gõ lệnh ngay.

---

## 1. Cấu Trúc Một HTTP Request

Khi bạn gõ `curl http://example.com`, trình khách (client) gửi một **HTTP Request** có cấu trúc:

```text
GET / HTTP/1.1                    <-- Request Line: Method + Path + HTTP Version
Host: example.com                 <-- Header: Tên miền đích
User-Agent: curl/7.68.0          <-- Header: Phần mềm gửi request
Accept: */*                       <-- Header: Loại nội dung chấp nhận
                                  <-- Dòng trống: Kết thúc phần Header
                                  <-- Body (nếu có, với POST/PUT)
```

### Các HTTP Method quan trọng cho DevOps

| Method | Mục Đích | Ví Dụ Thực Tế |
|---|---|---|
| **GET** | Lấy dữ liệu | `curl http://api.example.com/health` — Health check |
| **POST** | Gửi dữ liệu tạo mới | Webhook CI/CD gửi thông báo build |
| **PUT** | Cập nhật toàn bộ tài nguyên | Update cấu hình qua API |
| **DELETE** | Xóa tài nguyên | Xóa container/pod qua API |
| **HEAD** | Lấy header (không có body) | Kiểm tra nhanh server có sống không |

---

## 2. Cấu Trúc HTTP Response và Status Code

Server trả về một **HTTP Response** bao gồm:

```text
HTTP/1.1 200 OK                   <-- Status Line: Version + Status Code + Reason
Content-Type: text/html           <-- Header: Loại nội dung trả về
Content-Length: 1256              <-- Header: Kích thước body (bytes)
Connection: keep-alive            <-- Header: Giữ kết nối TCP
                                  <-- Dòng trống
<!doctype html>...                <-- Body: Nội dung trang web/API
```

### Các Nhóm Status Code Quan Trọng Cho DevOps

| Nhóm | Ý Nghĩa | Mã Thường Gặp | Ngữ Cảnh DevOps |
|---|---|---|---|
| **2xx** | Thành công | `200 OK`, `201 Created`, `204 No Content` | API trả về dữ liệu thành công, resource được tạo |
| **3xx** | Chuyển hướng | `301 Moved Permanently`, `302 Found`, `304 Not Modified` | HTTP redirect sang HTTPS, CDN cache |
| **4xx** | Lỗi phía Client | `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found` | API key sai, endpoint không tồn tại |
| **5xx** | Lỗi phía Server | `500 Internal Server Error`, `502 Bad Gateway`, `503 Service Unavailable`, `504 Gateway Timeout` | Backend crash, Nginx không kết nối được backend |

> **Mẹo debug cho DevOps:** Khi gặp lỗi `502 Bad Gateway`, vấn đề thường nằm ở **kết nối giữa Nginx và backend** (backend chưa chạy, port sai, hoặc process bị crash). Khi gặp `504 Gateway Timeout`, backend đang **xử lý quá lâu** vượt quá `proxy_read_timeout`.

---

## 3. Thực Hành: Phân Tích HTTP Với `curl -v`

Tham số `-v` (verbose) của `curl` cho phép bạn quan sát **toàn bộ quá trình giao tiếp HTTP**: từ bắt tay TCP, gửi request, đến nhận response.

### Gửi request tới một website thực tế

```bash
curl -v -s -o /dev/null http://example.com
```{{exec}}

Hãy phân tích output:
- Dòng bắt đầu bằng `>` là dữ liệu **client gửi đi** (Request).
- Dòng bắt đầu bằng `<` là dữ liệu **server trả về** (Response).
- Dòng bắt đầu bằng `*` là thông tin kết nối (TCP handshake, DNS resolution).

### Chỉ xem Response Headers (không tải body)

Lệnh `curl -I` (hoặc `--head`) gửi request bằng method `HEAD` để chỉ lấy headers:

```bash
curl -I http://example.com
```{{exec}}

Quan sát các header quan trọng:
- `Content-Type`: Định dạng nội dung trả về (`text/html`, `application/json`).
- `Content-Length`: Kích thước body tính bằng bytes.
- `Server`: Phần mềm web server đang chạy (Nginx, Apache, Cloudflare).
- `Cache-Control`: Chính sách cache (quan trọng cho CDN và browser caching).

### Gửi POST request với dữ liệu JSON

Trong CI/CD, các Webhook thường gửi dữ liệu bằng POST. Hãy mô phỏng với một public API:

```bash
curl -v -X POST https://httpbin.org/post \
  -H "Content-Type: application/json" \
  -d '{"service": "payment", "status": "healthy"}'
```{{exec}}

Quan sát:
- Method chuyển từ `GET` sang `POST`.
- Header `Content-Type: application/json` báo server dữ liệu là JSON.
- Body request chứa payload JSON.

---

## 4. HTTP Headers Quan Trọng Trong Hạ Tầng DevOps

| Header | Hướng | Mục Đích | Ví Dụ |
|---|---|---|---|
| `Host` | Request | Xác định tên miền đích (bắt buộc từ HTTP/1.1) | `Host: api.example.com` |
| `Content-Type` | Cả hai | Loại nội dung (MIME type) | `application/json`, `text/html` |
| `Authorization` | Request | Xác thực danh tính client | `Bearer <token>`, `Basic <base64>` |
| `User-Agent` | Request | Định danh phần mềm client | `curl/7.68.0`, `Mozilla/5.0` |
| `X-Real-IP` | Request (Proxy) | IP thật của client (do Reverse Proxy thêm vào) | `X-Real-IP: 203.0.113.50` |
| `X-Forwarded-For` | Request (Proxy) | Chuỗi IP mà request đã đi qua | `client, proxy1, proxy2` |
| `X-Forwarded-Proto` | Request (Proxy) | Giao thức gốc của client (http hoặc https) | `X-Forwarded-Proto: https` |
| `Cache-Control` | Response | Chính sách cache cho CDN và browser | `max-age=3600`, `no-cache` |
| `Set-Cookie` | Response | Thiết lập cookie phía client | Session ID, CSRF token |

---

## 5. Thử Thách & Xác Thực (Verification)

Hãy sử dụng `curl` để lấy **HTTP status code** của trang `http://example.com`:

1. Tìm lệnh `curl` phù hợp để chỉ xuất ra **duy nhất mã số status code** (ví dụ: `200`, `301`, `404`).

<details>
<summary>Xem gợi ý</summary>

- Tham số `-o /dev/null` bỏ qua body response.
- Tham số `-s` tắt thanh tiến trình (silent mode).
- Tham số `-w` cho phép định dạng output tùy chỉnh, ví dụ `"%{http_code}"` chỉ xuất status code.
</details>

2. Khi đã tìm được lệnh phù hợp, hãy **tự tay gõ lệnh** trên terminal để lưu kết quả vào file (thay thế `<STATUS_CODE>` bằng giá trị thực tế):
   ```bash
   echo "<STATUS_CODE>" > /tmp/http_status.txt
   ```
   *(Ví dụ: nếu status code là 200, hãy gõ `echo "200" > /tmp/http_status.txt`)*

3. Bấm nút **Check** bên dưới thanh điều khiển để hệ thống tự động chấm điểm!
