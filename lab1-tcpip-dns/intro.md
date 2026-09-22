Chào mừng bạn đến với bài lab **TCP/IP và DNS Trong DevOps**.

Trong kỹ thuật vận hành hệ thống hiện đại (Cloud Computing, Docker, Kubernetes, Microservices), **Networking** chính là "xương sống" kết nối toàn bộ hạ tầng. Từ việc thiết kế VPC trên AWS, cấu hình mạng Pod trong Kubernetes, đến quản lý kết nối TCP giữa các microservices và thiết lập Service Discovery qua DNS — tất cả đều đòi hỏi bạn phải nắm vững cách gói tin di chuyển trên mạng.

---

## Mục Tiêu Bài Học

Sau khi hoàn thành bài thực hành này, bạn sẽ:
1. **Làm chủ mô hình mạng TCP/IP 4 tầng** và cách các giao thức vận hành thực tế trên hệ điều hành Linux.
2. **Thành thạo kỹ năng Subnetting & CIDR**: tính toán số lượng IP khả dụng, xác định Network ID, Broadcast IP cho VPC và Docker/K8s Network.
3. **Phân tích Routing Table và Network Interfaces** bằng bộ công cụ Linux hiện đại (`iproute2`).
4. **Nắm vững Tầng Vận chuyển (Transport Layer)**: Phân biệt TCP vs UDP, theo dõi quá trình bắt tay 3 bước (3-Way Handshake) và debug cổng/socket bằng `ss` và `nc`.
5. **Làm chủ cơ chế phân giải tên miền DNS**: hiểu đường đi của một truy vấn DNS từ local cache, `/etc/hosts`, `systemd-resolved` đến Authoritative Name Server.
6. **Thành thạo công cụ chẩn đoán DNS**: sử dụng `dig` và các kỹ thuật debug sự cố phân giải tên miền trong môi trường production.

---

## Kiến Trúc Mô Hình TCP/IP vs OSI

| Tầng OSI (7 layers) | Tầng TCP/IP (4 layers) | Các Giao Thức Tiêu Biểu | Đơn Vị Dữ Liệu (PDU) | Trọng Tâm Bài Lab |
|---|---|---|---|---|
| Application / Presentation / Session | **Application Layer** | HTTP, HTTPS, DNS, SSH, gRPC | Data / Message | **Bước 3: DNS Resolution & Troubleshooting** |
| Transport | **Transport Layer** | TCP (tin cậy), UDP (tốc độ) | Segment (TCP) / Datagram (UDP) | **Bước 2: TCP/UDP, Port & Socket Debugging** |
| Network | **Internet Layer** | IPv4, IPv6, ICMP, Routing | Packet | **Bước 1: Subnetting, CIDR & Routing** |
| Data Link / Physical | **Network Access / Link Layer** | Ethernet, Wi-Fi, MAC Address | Frame / Bits | Khảo sát qua Network Interfaces |

---

## Tính Năng Tương Tác Trên Killercoda

- **Tự động hóa môi trường (Background Initialization)**: Các công cụ mạng (`ipcalc`, `dnsutils`, `netcat`,...) được hệ thống tự động chuẩn bị ngầm.
- **Thực thi lệnh nhanh**: Bấm trực tiếp vào các khối lệnh code trên hướng dẫn để tự động gửi và chạy lệnh trên terminal bên phải mà không cần sao chép thủ công.
- **Xác thực tự động (Verify Check)**: Mỗi bước đều có phần **Thử Thách**. Sau khi hoàn thành, hãy bấm nút **Check** ở thanh điều khiển để hệ thống tự động chấm điểm và đánh giá kết quả của bạn.

Bấm **START** hoặc chọn **Bước 1** để bắt đầu hành trình khám phá!
