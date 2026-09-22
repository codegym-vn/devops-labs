# Bước 1: Phân Tích Mạng, Subnetting & Ký Hiệu CIDR

Trong môi trường Cloud (AWS, Azure, GCP) và Containerization (Docker, Kubernetes), việc thiết kế dải IP và phân chia Subnet hợp lý giúp tối ưu hóa bảo mật (chia tách Public/Private subnet) và ngăn ngừa việc cạn kiệt địa chỉ IP.

---

## 1. Chuẩn Bị Môi Trường Thực Hành

Trước tiên, hãy cài đặt các gói công cụ mạng chuyên dụng trên Linux bao gồm `ipcalc`, `iproute2` và `dnsutils`:

```bash
apt-get update && apt-get install -y ipcalc iproute2 dnsutils curl
```{{exec}}

---

## 2. Nền Tảng Lý Thuyết: IPv4 và Ký Hiệu CIDR

Địa chỉ IPv4 gồm **32 bit**, chia làm 4 octet (mỗi octet 8 bit), phân cách bởi dấu chấm (ví dụ: `192.168.1.1`).

Một địa chỉ IP luôn bao gồm 2 phần:
- **Network ID (Phần mạng)**: Xác định mạng mà thiết bị trực thuộc.
- **Host ID (Phần máy)**: Định danh duy nhất cho thiết bị trong mạng đó.

### Ký hiệu CIDR (Classless Inter-Domain Routing)
CIDR biểu diễn số bit dành cho phần Network ID bằng dấu gạch chéo `/X`:
- `/24`: 24 bit mạng, 8 bit còn lại cho host -> (2^8 - 2 = 254) IP khả dụng cho thiết bị.
- `/16`: 16 bit mạng, 16 bit cho host -> (2^16 - 2 = 65,534) IP khả dụng.
- `/28`: 28 bit mạng, 4 bit cho host -> (2^4 - 2 = 14) IP khả dụng.

> **Lưu ý:** Thông thường ta phải trừ 2 vì:
> 1. **Địa chỉ đầu tiên**: Dành cho **Network Address** (địa chỉ định danh mạng).
> 2. **Địa chỉ cuối cùng**: Dành cho **Broadcast Address** (gửi dữ liệu tới toàn bộ thiết bị trong mạng).
> 
> *Đặc biệt trong AWS VPC*: AWS giữ riêng **5 địa chỉ IP** đầu/cuối trong mỗi subnet (.0, .1, .2, .3, và .255).

---

## 3. Thực Hành: Phân Tích Subnet Với `ipcalc`

Công cụ `ipcalc` giúp tính toán nhanh Netmask, Wildcard, Network Address, Broadcast và số Host tối đa.

### Phân tích dải mạng VPC chuẩn `/16`
Hãy phân tích dải mạng lớn thường dùng làm VPC trên Cloud:

```bash
ipcalc 10.0.0.0/16
```{{exec}}

Quan sát kết quả:
- **Netmask**: `255.255.0.0`
- **Hosts/Net**: `65534` máy chủ khả dụng.

### Phân tích Subnet cho Microservice `/24`
Dải mạng thường phân cho một cụm Node Kubernetes hoặc cụm Docker:

```bash
ipcalc 172.16.1.0/24
```{{exec}}

### Phân tích Private Subnet nhỏ cho Database `/28`
Dải mạng nhỏ tiết kiệm IP chỉ dành riêng cho cụm DB Master-Replica:

```bash
ipcalc 192.168.10.32/28
```{{exec}}

Quan sát:
- **HostMin**: `192.168.10.33`
- **HostMax**: `192.168.10.46`
- **Hosts/Net**: `14` máy chủ.

---

## 4. Khám Phá Network Interfaces & Bảng Định Tuyến (Routing Table)

Trên hệ điều hành Linux hiện đại, bộ công cụ `iproute2` (thay thế cho `ifconfig` và `route` đã cũ) là tiêu chuẩn bắt buộc.

### Xem danh sách card mạng (Interfaces)
Chạy lệnh sau để hiển thị ngắn gọn thông tin card mạng và IP đang được gán:

```bash
ip -brief address show
```{{exec}}

Bạn sẽ thấy ít nhất 2 interface:
- `lo`: Local Loopback (`127.0.0.1`), dùng cho giao tiếp nội bộ giữa các tiến trình trên cùng một máy chủ.
- `eth0` (hoặc `ensX`): Card mạng vật lý hoặc ảo, kết nối với mạng bên ngoài kèm theo địa chỉ IP và dải CIDR của máy lab.

### Xem bảng định tuyến (Routing Table)
Khi một packet muốn rời khỏi máy chủ, Linux sẽ tra cứu bảng routing để biết cần gửi qua card mạng nào và Gateway nào:

```bash
ip route show
```{{exec}}

Hãy chú ý dòng bắt đầu bằng `default via`:
```text
default via 172.x.x.1 dev eth0
```
- **default**: Áp dụng cho mọi gói tin có đích đến không nằm trong mạng nội bộ (`0.0.0.0/0`).
- **via <IP>**: Địa chỉ của **Default Gateway** (thường là Router hoặc VPC NAT Gateway) tiếp nhận gói tin để chuyển tiếp ra Internet.

---

## 5. Thử Thách Nhanh

Một team phát triển yêu cầu bạn cấp một subnet có thể chứa tối đa **25 containers**.
1. Subnet mask CIDR nào nhỏ nhất đáp ứng được yêu cầu trên?
   *(Gợi ý: 2^4 - 2 = 14 [không đủ], 2^5 - 2 = 30 [đủ] -> 32 - 5 = 27)*
2. Hãy chạy `ipcalc` với dải `10.20.0.0/27` để kiểm tra kết quả tính toán:

```bash
ipcalc 10.20.0.0/27
```{{exec}}

Khi đã nắm vững Subnetting và Interface mạng, hãy bấm sang **Bước 2** để tìm hiểu về DNS!
