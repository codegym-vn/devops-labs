# Bước 2: Tầng Transport - TCP vs UDP, Quản Lý Port & Debugging Socket

Trong mô hình TCP/IP, **Tầng Vận chuyển (Transport Layer)** chịu trách nhiệm điều phối việc truyền dữ liệu giữa các tiến trình chạy trên các máy chủ khác nhau. Đối với DevOps Engineer, khi gặp các lỗi kinh điển như `Connection refused`, `Connection timed out` hay `Port already in use`, việc hiểu rõ socket và cơ chế hoạt động của TCP/UDP là chìa khóa để xử lý sự cố nhanh chóng.

---

## 1. Nền Tảng: Port, Socket và Giao Thức TCP vs UDP

### Port và Socket là gì?
- **IP Address**: Định danh thiết bị trên mạng (đến đúng máy chủ).
- **Port**: Định danh tiến trình/ứng dụng cụ thể chạy trên máy chủ đó (0 - 65535).
  - *Well-known Ports (0 - 1023)*: Cần quyền root (`22` SSH, `80` HTTP, `443` HTTPS, `53` DNS).
  - *Registered Ports (1024 - 49151)*: Thường dành cho ứng dụng (`3000` Node.js, `5432` PostgreSQL, `6379` Redis, `8080` Web Backend).
  - *Dynamic/Ephemeral Ports (49152 - 65535)*: Cổng tạm thời do OS cấp phát cho client khi tạo kết nối ra ngoài.
- **Socket**: Sự kết hợp giữa `[IP Address] : [Port]` tạo thành một điểm cuối giao tiếp duy nhất (ví dụ: `192.168.1.10:8080`).

### So sánh TCP vs UDP trong thực tế

| Đặc tính | TCP (Transmission Control Protocol) | UDP (User Datagram Protocol) |
|---|---|---|
| **Cơ chế** | Hướng kết nối (Connection-oriented) | Phi kết nối (Connectionless) |
| **Độ tin cậy** | Có ACK, tự động truyền lại gói tin bị mất, sắp xếp đúng thứ tự | Không đảm bảo gói tin tới đích, không truyền lại |
| **Bắt tay** | Có (3-Way Handshake) | Không có bắt tay |
| **Tốc độ** | Chậm hơn do chi phí kiểm soát và bắt tay | Cực nhanh, độ trễ tối thiểu |
| **Ứng dụng DevOps** | HTTP/HTTPS, gRPC, Database, Git, SSH | DNS query, DHCP, Syslog, Metrics (StatsD), QUIC (HTTP/3) |

---

## 2. Quá Trình Bắt Tay 3 Bước (TCP 3-Way Handshake)

Trước khi gửi bất kỳ byte dữ liệu nào qua TCP, Client và Server phải thực hiện bắt tay:

```text
  Client                               Server (Đang ở trạng thái LISTEN)
    │                                     │
    │ ─── 1. SYN (Synchronize Sequence) ─>│ [Server chuyển sang SYN_RCVD]
    │                                     │
    │ <── 2. SYN-ACK (Acknowledge) ───────│ [Client chuyển sang ESTABLISHED]
    │                                     │
    │ ─── 3. ACK (Acknowledge) ──────────>│ [Server chuyển sang ESTABLISHED]
    │                                     │
[Bắt đầu truyền dữ liệu Application: HTTP GET, TLS Handshake...]
```

### Các trạng thái Socket quan trọng cần nhớ
- `LISTEN`: Tiến trình server đang chờ client kết nối tới cổng.
- `ESTABLISHED`: Hai đầu đã bắt tay xong và sẵn sàng trao đổi dữ liệu.
- `TIME_WAIT`: Socket đã đóng nhưng hệ điều hành giữ lại trong giây lát để đảm bảo các gói tin còn trôi nổi trên mạng được xử lý hết.
- `CLOSE_WAIT`: Phía bên kia đã đóng kết nối, server đang chờ ứng dụng nội bộ giải phóng tài nguyên.

---

## 3. Khảo Sát Socket Đang Mở Với `ss` (Socket Statistics)

Công cụ `ss` (thuộc bộ `iproute2`) là giải pháp thay thế nhanh và hiệu quả hơn nhiều so với `netstat` đã lỗi thời.

### Liệt kê tất cả các cổng đang lắng nghe (`LISTEN`)
Chạy lệnh sau để kiểm tra xem trên máy chủ có những dịch vụ nào đang mở port:

```bash
ss -tulpn
```{{exec}}

Giải thích các tham số:
- `-t`: Hiển thị socket **TCP**.
- `-u`: Hiển thị socket **UDP**.
- `-l`: Chỉ lọc các socket đang **Listening** (lắng nghe).
- `-p`: Hiển thị tên tiến trình (Process) và PID đang nắm giữ port.
- `-n`: Hiển thị dạng số (Numeric port, ví dụ `22` thay vì chữ `ssh`).

Quan sát cột `Local Address:Port`:
- `0.0.0.0:22` hoặc `*:22`: Đang lắng nghe trên **tất cả** các card mạng của máy chủ.
- `127.0.0.1:xxx`: Chỉ lắng nghe cục bộ (Localhost), bên ngoài không thể truy cập trực tiếp.

---

## 4. Kiểm Tra Kết Nối Port Bằng Netcat (`nc`) và `curl`

Khi một container không gọi được sang database hay microservice khác, ta cần kiểm tra xem port có thông suốt không trước khi nghi ngờ lỗi code ứng dụng.

### Dùng `nc -zv` để test nhanh kết nối cổng (Port Scanning)
Tùy chọn `-z` (zero-I/O: chỉ quét bắt tay, không gửi dữ liệu) và `-v` (verbose: hiển thị chi tiết):

Kiểm tra cổng 22 (SSH) trên localhost:
```bash
nc -zv 127.0.0.1 22
```{{exec}}

Nếu port mở và sẵn sàng, bạn sẽ thấy thông báo `Connection to 127.0.0.1 22 port [tcp/*] succeeded!`.

Thử kiểm tra một cổng không có dịch vụ nào chạy (ví dụ 9999):
```bash
nc -zvw2 127.0.0.1 9999
```{{exec}}

Bạn sẽ nhận được ngay phản hồi `Connection refused` (Gói RST/ACK từ kernel báo cổng đang đóng).

### Phân tích quá trình bắt tay TCP với `curl -v`
Lệnh `curl -v` cho phép bạn quan sát thời điểm bắt tay TCP diễn ra trước khi giao thức HTTP bắt đầu:

```bash
curl -v -s -o /dev/null https://www.google.com
```{{exec}}

Chú ý dòng:
```text
* Connected to www.google.com (142.250.x.x) port 443
```
Đó chính là thời điểm hoàn thành TCP 3-Way Handshake!

---

## 5. Thử Thách & Xác Thực (Verification)

Một ứng dụng web backend cần được triển khai và lắng nghe trên cổng **`8080`**.

1. Hãy khởi chạy một dịch vụ web giả lập chạy ngầm trên cổng `8080`:
```bash
python3 -m http.server 8080 > /dev/null 2>&1 &
```{{exec}}

2. Kiểm tra xem port 8080 đã ở trạng thái `LISTEN` hay chưa:
```bash
ss -tlpn | grep 8080
```{{exec}}

3. Dùng `nc` kiểm tra kết nối tới port vừa mở:
```bash
nc -zv 127.0.0.1 8080
```{{exec}}

4. Bấm nút **Check** bên dưới thanh điều khiển để hệ thống tự động xác thực trạng thái socket của bạn!
