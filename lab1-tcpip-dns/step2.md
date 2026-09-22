# Bước 2: Cơ Chế Phân Giải & Kiểm Thử DNS

Trong kiến trúc Microservices và Kubernetes, **DNS** (Domain Name System) đóng vai trò sống còn trong việc **Service Discovery** (khám phá dịch vụ). Khi một Service A gọi Service B qua địa chỉ `http://payment-service:8080`, hệ thống phụ thuộc hoàn toàn vào DNS (như CoreDNS trong K8s) để tìm ra IP của Pod đích.

---

## 1. Cơ Chế Phân Giải DNS Hoạt Động Như Thế Nào?

Khi bạn gõ lệnh `curl https://example.com`, hệ điều hành Linux thực hiện tuần tự:

```text
[Ứng dụng: curl]
       │
       ▼
1. Kiểm tra Cache & File Cục Bộ (/etc/hosts)
       │ (nếu không thấy)
       ▼
2. Đọc file cấu hình DNS Client (/etc/resolv.conf)
       │ (gửi query tới Recursive Resolver, VD: 8.8.8.8 hoặc CoreDNS)
       ▼
3. Root Name Server (.) ──> 4. TLD Name Server (.com) ──> 5. Authoritative Server (Cloudflare/Route53)
       │
       ▼
Trả về địa chỉ IP (A / AAAA Record) cho máy client
```

---

## 2. Kiểm Tra Cấu Hình DNS Cục Bộ Trên Linux

### File cấu hình DNS Resolver: `/etc/resolv.conf`
Xem địa chỉ DNS Server mà hệ thống đang sử dụng:

```bash
cat /etc/resolv.conf
```{{exec}}

- `nameserver <IP>`: Địa chỉ máy chủ DNS tiếp nhận các truy vấn từ máy này.
- `search <domain>`: Domain suffix tự động nối vào sau tên hostname ngắn (rất quan trọng trong Kubernetes, ví dụ `default.svc.cluster.local`).

### File phân giải cục bộ: `/etc/hosts`
File này luôn được ưu tiên kiểm tra trước khi gửi truy vấn ra ngoài:

```bash
cat /etc/hosts
```{{exec}}

### Thực hành: Kỹ thuật ghi đè DNS trong `/etc/hosts`
DevOps thường dùng cách này để kiểm thử một website trên máy chủ mới trước khi trỏ DNS chính thức:

Thêm một bản ghi giả lập:
```bash
echo "127.0.0.1 myapp.internal" >> /etc/hosts
```{{exec}}

Kiểm tra xem tên miền `myapp.internal` đã phân giải về `127.0.0.1` chưa:
```bash
getent hosts myapp.internal
```{{exec}}

Thử ping thử nghiệm:
```bash
ping -c 2 myapp.internal
```{{exec}}

---

## 3. Chẩn Đoán DNS Chuyên Sâu Với `dig`

`dig` (Domain Information Groper) là công cụ mạnh mẽ và chi tiết nhất để kiểm tra DNS records.

### Truy vấn cơ bản và phân tích gói tin DNS
Chạy lệnh `dig` đối với domain `google.com`:

```bash
dig google.com
```{{exec}}

Hãy phân tích các phần quan trọng trong output:
1. **HEADER**: Chứa `status: NOERROR` (thành công) hoặc `NXDOMAIN` (tên miền không tồn tại), cùng cờ cờ `qr`, `rd`, `ra`.
2. **QUESTION SECTION**: Câu hỏi được gửi đi (tìm record loại `A` của `google.com`).
3. **ANSWER SECTION**: Kết quả trả về gồm tên miền, **TTL** (Time To Live - thời gian cache tính bằng giây), loại record, và IP.
4. **SERVER**: IP máy chủ DNS đã trả lời truy vấn.
5. **WHEN**: Thời gian phản hồi (`Query time: ... msec`).

### Lấy kết quả ngắn gọn với `+short`
Trong các shell script tự động hóa, ta thường dùng cờ `+short` để chỉ lấy địa chỉ IP:

```bash
dig google.com +short
```{{exec}}

### Truy vấn các loại Record khác nhau
Một domain có nhiều loại bản ghi phục vụ các mục đích khác nhau:

- **MX (Mail Exchange)** - Máy chủ email:
```bash
dig google.com MX +short
```{{exec}}

- **TXT (Text)** - Thường dùng xác thực sở hữu domain, cấu hình SPF/DKIM chống giả mạo email:
```bash
dig google.com TXT +short
```{{exec}}

- **CNAME (Canonical Name)** - Tên miền bí danh (alias):
```bash
dig www.github.com CNAME +short
```{{exec}}

---

## 4. Chỉ Định Trực Tiếp DNS Server Cần Tra Cứu

Đôi khi DNS nội bộ gặp sự cố hoặc kết quả bị cache sai, bạn có thể kiểm tra chéo bằng cách chỉ định DNS Server công cộng thông qua ký tự `@`:

Hỏi Google DNS (`8.8.8.8`):
```bash
dig @8.8.8.8 cloudflare.com +short
```{{exec}}

Hỏi Cloudflare DNS (`1.1.1.1`):
```bash
dig @1.1.1.1 cloudflare.com +short
```{{exec}}

---

## 5. Theo Dõi Toàn Bộ Quy Trình Phân Cấp Với `+trace`

Tham số `+trace` mô phỏng hành trình đi từ gốc (Root DNS) đến máy chủ Authoritative:

```bash
dig kubernetes.io +trace
```{{exec}}

Quan sát thứ tự:
1. Truy vấn danh sách 13 Root Server (`a.root-servers.net` đến `m.root-servers.net`).
2. Root Server giới thiệu sang TLD Name Server quản lý đuôi `.io`.
3. TLD Server giới thiệu sang Name Server quản trị của `kubernetes.io`.

---

## 6. Quy Trình Debug DNS Dành Cho DevOps Engineer

Khi ứng dụng báo lỗi `Could not resolve host: service-x`:
1. **Bước 1**: Kiểm tra file `/etc/resolv.conf` xem có nameserver nào được khai báo không.
2. **Bước 2**: Thử truy vấn bằng IP của DNS server: `dig @<nameserver_ip> service-x`.
3. **Bước 3**: Kiểm tra kết nối mạng tới DNS server qua cổng 53: `nc -zvw3 <nameserver_ip> 53`.

Hoàn thành xuất sắc! Hãy bấm **Next** để xem phần tổng kết và bài tập đánh giá.
