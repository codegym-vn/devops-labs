# Lab 1: TCP/IP và DNS Trong Môi Trường DevOps

Chào mừng bạn đến với bài lab **TCP/IP và DNS Trong DevOps**. 

Trong kỹ thuật vận hành hệ thống hiện đại (Cloud Computing, Docker, Kubernetes, Microservices), **Networking** chính là "xương sống" kết nối toàn bộ hạ tầng. Dù bạn deploy ứng dụng lên AWS VPC, cấu hình mạng Pod trong Kubernetes với Calico/Cilium, hay thiết lập Service Discovery, việc nắm vững cách thức gói tin di chuyển và cách thức tên miền được phân giải là kỹ năng bắt buộc của một DevOps Engineer.

---

## Mục Tiêu Bài Học

Sau khi hoàn thành bài thực hành này, bạn sẽ:
1. **Hiểu rõ mô hình TCP/IP 4 tầng** và cách hoạt động thực tế trên hệ điều hành Linux.
2. **Làm chủ kỹ năng phân chia Subnetting & CIDR**: tính toán số lượng IP khả dụng, xác định Network ID, Broadcast IP cho hệ thống VPC hoặc Docker Network.
3. **Phân tích Routing Table và Network Interfaces** bằng các công cụ Linux hiện đại (`iproute2`).
4. **Nắm vững cơ chế phân giải tên miền DNS**: hiểu đường đi của một truy vấn DNS từ local cache, `/etc/hosts` đến Authoritative Name Server.
5. **Thành thạo công cụ chẩn đoán DNS**: sử dụng `dig`, `nslookup`, `drill` để debug các lỗi mạng thường gặp trong môi trường production.

---

## Kiến Trúc Mô Hình TCP/IP vs OSI

| Tầng OSI (7 layers) | Tầng TCP/IP (4 layers) | Các Giao Thức Tiêu Biểu | Đơn Vị Dữ Liệu (PDU) |
|---|---|---|---|
| Application / Presentation / Session | **Application Layer** | HTTP, HTTPS, DNS, SSH, gRPC | Data / Message |
| Transport | **Transport Layer** | TCP (tin cậy), UDP (tốc độ) | Segment (TCP) / Datagram (UDP) |
| Network | **Internet Layer** | IPv4, IPv6, ICMP, ARP | Packet |
| Data Link / Physical | **Network Access / Link Layer** | Ethernet, Wi-Fi, MAC Address | Frame / Bits |

> **Lưu ý tương tác trên Killercoda:**  
> Bấm vào các khối lệnh code có biểu tượng thực thi để lệnh tự động được gửi vào terminal bên phải, hoặc bạn có thể tự tay gõ lệnh để ghi nhớ tốt hơn.

Bấm **START** hoặc chọn **Bước 1** để bắt đầu hành trình khám phá Subnetting & CIDR!
