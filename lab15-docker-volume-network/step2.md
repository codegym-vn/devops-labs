# Bước 2: Cấu Hình Custom Bridge Network & Cơ Chế Phân Giải Tên Miền Embedded DNS

Trong bước này, bạn sẽ phân tích sự khác biệt giữa mạng mặc định (`default bridge`) và mạng tùy biến (**User-defined Custom Bridge**), khởi tạo mạng `app-net` với dải Subnet quy chuẩn, và kiểm chứng cơ chế **Embedded DNS** của Docker.

---

## 1. Lý Thuyết: Default Bridge vs Custom Bridge Network

Khi cài đặt Docker, hệ thống tự động tạo ra một mạng cầu nối mặc định tên là `bridge` (tương ứng với card mạng `docker0` trên Linux host). Tuy nhiên, mạng này có nhiều hạn chế nghiêm trọng trong môi trường doanh nghiệp:

| Tiêu chí so sánh | Default Bridge (`bridge`) | Custom Bridge (`docker network create`) |
| :--- | :--- | :--- |
| **Phân giải DNS (Service Discovery)** | ❌ **Không hỗ trợ.** Buộc phải dùng IP hoặc flag `--link` (lỗi thời) | ✅ **Tự động phân giải qua Container Name / Alias** |
| **Máy chủ DNS nội bộ** | Kế thừa `/etc/resolv.conf` từ máy host | Tích hợp **Embedded DNS Server** tại `127.0.0.11` |
| **Tính cô lập & Bảo mật** | Kém: Mọi container không chỉ định network đều gom chung vào đây | Cao: Chỉ các container cùng custom network mới giao tiếp được |
| **Gắn/ngắt kết nối động** | Phải dừng container mới đổi được mạng | Hỗ trợ gắn nóng (`docker network connect/disconnect`) |

```
 ┌──────────────────────────────────────────────────────────────┐
 │ Custom Bridge: app-net (172.28.0.0/16)                       │
 │                                                              │
 │   ┌───────────────────┐           ┌───────────────────┐      │
 │   │   service-beta    │           │   service-alpha   │      │
 │   │ (IP: 172.28.0.3)  │           │ (IP: 172.28.0.2)  │      │
 │   └─────────┬─────────┘           └─────────▲─────────┘      │
 │             │                               │                │
 │             │   1. DNS Query: "service-alpha"?               │
 │             ▼                               │                │
 │   ┌───────────────────┐                     │                │
 │   │   Embedded DNS    │                     │                │
 │   │   (127.0.0.11)    │                     │                │
 │   └─────────┬─────────┘                     │                │
 │             │   2. Trả lời: 172.28.0.2      │                │
 │             └───────────────────────────────┘                │
 └──────────────────────────────────────────────────────────────┘
```

---

## 2. Thực Hành

### 2.1 — Liệt kê các mạng hiện có trên Docker Host

```bash
docker network ls
```{{exec}}

Bạn sẽ thấy 3 mạng mặc định: `bridge`, `host`, và `none`.

---

### 2.2 — Khởi tạo Custom Bridge Network (`app-net`)

Tạo một mạng cầu nối tùy biến tên là `app-net`, sử dụng driver `bridge` và quy hoạch dải Subnet `172.28.0.0/16`:

```bash
docker network create \
  --driver bridge \
  --subnet 172.28.0.0/16 \
  app-net
```{{exec}}

Kiểm tra thông tin chi tiết của mạng vừa tạo:

```bash
docker network inspect app-net
```{{exec}}

Quan sát trường `"IPAM" -> "Config"` để xác nhận dải Subnet `172.28.0.0/16` và Gateway `172.28.0.1`.

---

### 2.3 — Khởi chạy 2 Container trên cùng mạng `app-net`

Khởi chạy container đầu tiên có tên `service-alpha`:

```bash
docker run -d --name service-alpha \
  --network app-net \
  alpine:3.19 \
  sleep 3600
```{{exec}}

Khởi chạy container thứ hai có tên `service-beta`:

```bash
docker run -d --name service-beta \
  --network app-net \
  alpine:3.19 \
  sleep 3600
```{{exec}}

---

### 2.4 — Kiểm chứng Cơ Chế Phân Giải Tên Miền (Embedded DNS)

Thực hiện lệnh `ping` từ `service-beta` sang `service-alpha` trực tiếp bằng **Container Name** thay vì dùng địa chỉ IP:

```bash
docker exec service-beta ping -c 3 service-alpha
```{{exec}}

Quan sát kết quả: Lệnh ping thực hiện thành công ngay lập tức! Bạn sẽ thấy IP đích được phân giải tự động thành một địa chỉ nằm trong dải `172.28.x.x`.

Khám phá máy chủ DNS được cấu hình bên trong container:

```bash
docker exec service-beta cat /etc/resolv.conf
```{{exec}}

Dòng `nameserver 127.0.0.11` chứng minh Docker đã tích hợp máy chủ phân giải tên miền nội bộ trực tiếp cho container này.

---

## 3. Hoàn Thành & Xác Minh

Nhấn nút **Check** ở góc dưới bên trái để hệ thống tự động kiểm tra:
1. Network `app-net` tồn tại với driver `bridge` và dải subnet `172.28.0.0/16`.
2. Cả hai container `service-alpha` và `service-beta` đều đang chạy trên mạng `app-net`.
3. Kiểm tra khả năng phân giải DNS và ping thành công giữa hai container.
