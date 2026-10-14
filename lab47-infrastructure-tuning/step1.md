# Bước 1: Khảo Sát Giới Hạn Mặc Định Của Nginx & Linux Kernel

Trước khi tiến hành đo lường tải cao, bạn cần khảo sát cấu hình hiện tại của Nginx Reverse Proxy và các tham số giới hạn mạng của hệ điều hành Linux.

---

### 1. Khảo Sát Tệp Cấu Hình Nginx Hiện Tại

Mở tệp cấu hình Nginx tại `/root/infra-opt-lab/nginx/nginx.conf`:

```bash
cat /root/infra-opt-lab/nginx/nginx.conf
```

*Nhận diện 3 điểm nghẽn nghiêm trọng:*
1. **Giới hạn kết nối đồng thời cực thấp:**
   ```nginx
   events {
       worker_connections 64;
   }
   ```
   Chỉ cho phép tối đa 64 kết nối đồng thời trên một tiến trình worker. Nếu có 80 người dùng truy cập cùng lúc, các request dư thừa sẽ bị từ chối ngay lập tức.
2. **Thiếu cơ chế KeepAlive Upstream:**
   ```nginx
   upstream backend_nodes {
       server 127.0.0.1:8080;
   }
   ```
   Khối `upstream` không có chỉ thị `keepalive`, khiến Nginx phải mở một kết nối TCP riêng biệt cho từng request đơn lẻ.
3. **Mặc định dùng HTTP 1.0:**
   Trong khối `location /`, Nginx chưa thiết lập `proxy_http_version 1.1` và `proxy_set_header Connection ""`.

---

### 2. Khảo Sát Các Tham Số Hạt Nhân Linux Kernel Hiện Tại

Sử dụng lệnh `sysctl` để kiểm tra các giới hạn mạng của Linux:

```bash
sysctl net.core.somaxconn
sysctl net.ipv4.tcp_max_syn_backlog
sysctl net.ipv4.ip_local_port_range
```

*Ghi nhận:*
* `net.core.somaxconn = 128` (hoặc 4096 tùy kernel mặc định nhưng chưa được tối ưu cho tải đột biến).
* Hàng đợi socket lắng nghe (Listen Queue) quá ngắn sẽ khiến các gói tin bắt tay TCP bị loại bỏ (drop) khi có lưu lượng truy cập ồ ạt.

---

### 3. Kiểm Tra Kết Nối Qua Nginx Tới Backend

Gửi một request kiểm tra thông suốt qua cổng 80:

```bash
curl -s http://localhost:80/api/data | jq .
```

*Kết quả:*
```json
{
  "server": "backend-node-1",
  "status": "OK"
}
```

Ở điều kiện tải 1 request, hệ thống hoạt động bình thường. Tuy nhiên, điều này sẽ thay đổi hoàn toàn khi chúng ta tăng tải đồng thời ở Bước 2.

Sau khi đã khảo sát xong các giới hạn cấu hình, nhấn **Check** để hoàn thành Bước 1!
