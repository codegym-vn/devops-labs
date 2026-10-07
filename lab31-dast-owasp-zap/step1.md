# Bước 1: Khởi Chạy Ứng Dụng Web Mục Tiêu & Khảo Sát Bề Mặt Tấn Công

Trước khi chạy công cụ DAST, ứng dụng mục tiêu phải đang hoạt động thực tế trên máy chủ để công cụ có thể gửi các HTTP request thăm dò.

---

### 1. Khởi chạy ứng dụng Web trên cổng 3000

Di chuyển vào thư mục `/root/dast-target-app` và khởi động dịch vụ bằng tiến trình chạy ngầm:

```bash
cd /root/dast-target-app
nohup node server.js > app.log 2>&1 &
```

Chờ 2 giây và kiểm tra tiến trình đang lắng nghe trên cổng 3000:

```bash
sleep 2
lsof -i :3000 || netstat -tlpn | grep 3000
```

Kiểm tra API phản hồi trạng thái:

```bash
curl -s http://localhost:3000/api/health | jq .
```

---

### 2. Khảo sát bề mặt tấn công qua HTTP Response Headers

Trong kiểm thử hộp đen, tin tặc hoặc công cụ quét DAST sẽ kiểm tra các thông số phản hồi trong Header của máy chủ:

```bash
curl -I http://localhost:3000
```

Quan sát kết quả trả về:
```http
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: text/html; charset=utf-8
Content-Length: ...
Date: ...
Connection: keep-alive
```

Nhận xét các điểm yếu ban đầu:
1. **Rò rỉ thông tin công nghệ:** Header `X-Powered-By: Express` tiết lộ trực tiếp cho kẻ tấn công framework backend đang sử dụng, tạo tiền đề cho các cuộc tấn công khai thác lỗ hổng đặc thù của Node.js/Express.
2. **Thiếu cơ chế chống Clickjacking:** Không có tiêu đề `X-Frame-Options`. Kẻ tấn công có thể nhúng trang web này vào một `<iframe>` ẩn trên trang web độc hại để lừa người dùng nhấp chuột ngoài ý muốn.
3. **Thiếu chính sách bảo mật nội dung (CSP):** Trình duyệt không được cung cấp danh sách trắng các nguồn tải script hợp lệ, mở đường cho tấn công XSS.
4. **Thiếu chỉ thị chống MIME-Sniffing:** Thiếu `X-Content-Type-Options: nosniff`.

Nhấn **Check** để hoàn thành bước 1!
