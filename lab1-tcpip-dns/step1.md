# Bước 1: Tầng Network - Subnetting, Ký Hiệu CIDR & Định Tuyến

Trong môi trường Cloud (AWS VPC, Azure VNet, GCP VPC) và Containerization (Docker, Kubernetes), việc thiết kế dải IP và phân chia Subnet hợp lý giúp tối ưu hóa bảo mật (tách biệt Public/Private Subnet) và ngăn ngừa việc cạn kiệt địa chỉ IP cho Pods/Containers.

> **Lưu ý môi trường:** Hệ thống Killercoda đã tự động cài đặt sẵn các gói công cụ mạng chuyên dụng (`ipcalc`, `iproute2`, `dnsutils`, `netcat`, `curl`) ở chế độ nền. Bạn có thể bắt đầu gõ lệnh ngay mà không cần chờ đợi.

---

## 1. Nền Tảng Lý Thuyết: IPv4 và Ký Hiệu CIDR

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

## 2. Thực Hành: Phân Tích Subnet Với `ipcalc`

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

## 3. Khám Phá Network Interfaces & Bảng Định Tuyến (Routing Table)

Trên hệ điều hành Linux hiện đại, bộ công cụ `iproute2` (thay thế cho `ifconfig` và `route` đã cũ) là tiêu chuẩn bắt buộc.

### Xem danh sách card mạng (Interfaces)
Chạy lệnh sau để hiển thị ngắn gọn thông tin card mạng và IP đang được gán:

```bash
ip -brief address show
```{{exec}}

Quan sát kết quả thực tế trên môi trường lab:
- `lo`: **Local Loopback** (`127.0.0.1/8`), dùng cho giao tiếp nội bộ giữa các tiến trình trên cùng một máy chủ. Trạng thái `UNKNOWN` là bình thường với loopback.
- `enp1s0` (hoặc `eth0`, `ensX`): Card mạng chính kết nối với hạ tầng mạng bên ngoài, hiển thị địa chỉ IP và dải CIDR thực tế của máy lab (ví dụ: `172.30.1.2/24`).
- `docker0`: Card mạng cầu nối ảo (Virtual Bridge) được Docker daemon khởi tạo sẵn (`172.17.0.1/16`) để làm gateway kết nối các container.

### Xem bảng định tuyến (Routing Table)
Khi một packet muốn rời khỏi máy chủ, Linux sẽ tra cứu bảng routing để biết cần gửi qua card mạng nào và Gateway nào:

```bash
ip route show
```{{exec}}

Hãy chú ý dòng bắt đầu bằng `default via`:
```text
default via 172.30.1.1 dev enp1s0
```
- **default**: Áp dụng cho mọi gói tin có đích đến không nằm trong mạng nội bộ (`0.0.0.0/0`).
- **via <IP>**: Địa chỉ của **Default Gateway** (thường là Router hoặc VPC NAT Gateway) tiếp nhận gói tin để chuyển tiếp ra Internet.
- **dev <interface>**: Tên card mạng mà gói tin sẽ rời máy để đi tới Gateway (ở đây là `enp1s0`).

---

## 4. Thử Thách & Xác Thực (Verification)

Một team phát triển yêu cầu bạn cấp một subnet có thể chứa tối đa **25 containers**.

1. Hãy tìm tiền tố CIDR nhỏ nhất (ví dụ: `26`, `27`, `28`,...) đáp ứng yêu cầu trên.

<details>
<summary>Xem gợi ý công thức tính toán</summary>

- Công thức số host khả dụng: (2^h - 2 >= 25) (với h là số bit dành cho host).
- Thử h = 4 -> (2^4 - 2 = 14) (không đủ cho 25 containers).
- Thử h = 5 -> (2^5 - 2 = 30) (đủ cho 25 containers).
- Tiền tố CIDR = 32 - h = 32 - 5 = 27.
</details>

2. Sau khi đã tìm ra đáp án, hãy lưu giá trị prefix vào file `/tmp/subnet.txt`:

```bash
echo "27" > /tmp/subnet.txt
```{{exec}}

3. Dùng `ipcalc` kiểm tra lại số máy chủ hợp lệ:

```bash
ipcalc 10.20.0.0/27
```{{exec}}

4. Bấm nút **Check** bên dưới thanh điều khiển để hệ thống tự động xác thực đáp án của bạn!
