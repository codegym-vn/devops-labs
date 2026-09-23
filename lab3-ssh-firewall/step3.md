# Bước 3: Tường Lửa UFW - Kiểm Soát Traffic & Chống Brute-Force

Sau khi đã gia cố SSH (Lớp 1) và thiết lập tunnel an toàn (Lớp 2), bước cuối cùng là triển khai **Lớp 3: Tường lửa** để kiểm soát toàn bộ traffic mạng vào/ra server. **UFW (Uncomplicated Firewall)** là frontend thân thiện cho `iptables` — công cụ tường lửa tiêu chuẩn trên Ubuntu/Debian.

---

## 1. UFW Hoạt Động Như Thế Nào?

UFW kiểm soát traffic dựa trên tập hợp các **rules** (quy tắc). Mỗi gói tin đến hoặc đi đều được đối chiếu với danh sách rules theo thứ tự, rule khớp đầu tiên sẽ được áp dụng:

```text
  Gói tin đến                           Gói tin đi
       │                                     │
       ▼                                     ▼
  ┌─────────────┐                     ┌─────────────┐
  │  Rule 1: Allow SSH 2222  │        │  Default: Allow  │
  │  Rule 2: Allow HTTP 80   │        │  (Cho phép tất cả│
  │  Rule 3: Allow HTTPS 443 │        │   traffic đi ra) │
  │  Rule 4: Deny Telnet 23  │        └─────────────┘
  │  ...                     │
  │  Default: Deny           │
  │  (Chặn mọi thứ còn lại) │
  └─────────────┘
```

---

## 2. Kiểm Tra Trạng Thái UFW Hiện Tại

```bash
ufw status verbose
```{{exec}}

Kết quả `Status: inactive` — tường lửa chưa được bật.

---

## 3. Thiết Lập Chính Sách Mặc Định

Trước khi bật UFW, hãy thiết lập chính sách mặc định an toàn:

```bash
ufw default deny incoming
ufw default allow outgoing
```{{exec}}

- **deny incoming**: Chặn tất cả traffic đến (trừ các rule cho phép cụ thể).
- **allow outgoing**: Cho phép tất cả traffic đi ra (server cần truy cập Internet để cập nhật, gọi API...).

---

## 4. Thêm Rules Cho Phép Dịch Vụ Cần Thiết

### Cho phép SSH trên port tùy chỉnh (2222)

```bash
ufw allow 2222/tcp comment 'SSH custom port'
```{{exec}}

### Cho phép HTTP và HTTPS

```bash
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
```{{exec}}

### Chặn Telnet (giao thức không mã hóa, nguy hiểm)

```bash
ufw deny 23/tcp comment 'Block Telnet'
```{{exec}}

---

## 5. Bật Tường Lửa

```bash
ufw --force enable
```{{exec}}

> **Lưu ý:** Tham số `--force` bỏ qua câu hỏi xác nhận tương tác. Trong production, hãy luôn đảm bảo đã thêm rule cho phép SSH **trước khi** bật UFW, nếu không bạn sẽ bị khóa khỏi server!

Kiểm tra trạng thái sau khi bật:

```bash
ufw status numbered
```{{exec}}

Bạn sẽ thấy danh sách rules được đánh số, cho phép quản lý từng rule cụ thể.

---

## 6. Rate Limiting - Chống Brute-Force SSH

UFW tích hợp sẵn tính năng **rate limiting** để tự động chặn IP nào kết nối quá nhanh (mặc định: 6 lần/30 giây):

```bash
ufw delete allow 2222/tcp
ufw limit 2222/tcp comment 'Rate limit SSH'
```{{exec}}

Kiểm tra rule đã được cập nhật:

```bash
ufw status verbose
```{{exec}}

Bạn sẽ thấy rule cho port 2222 chuyển từ `ALLOW` sang `LIMIT` — bất kỳ IP nào thử kết nối quá 6 lần trong 30 giây sẽ bị tự động chặn.

---

## 7. Cho Phép Truy Cập Từ Dải IP Cụ Thể

Trong production, một số dịch vụ chỉ nên cho phép truy cập từ mạng nội bộ:

```bash
ufw allow from 10.0.0.0/24 to any port 5432 proto tcp comment 'PostgreSQL internal only'
```{{exec}}

Rule này chỉ cho phép các máy trong dải `10.0.0.0/24` truy cập PostgreSQL (port 5432). Mọi IP khác đều bị chặn.

---

## 8. Quản Lý và Xóa Rules

Xem danh sách rules có đánh số:

```bash
ufw status numbered
```{{exec}}

Xóa một rule cụ thể (ví dụ rule số 6 — PostgreSQL vừa thêm):

```bash
ufw delete 6
```{{exec}}

> **Lưu ý:** Sau khi xóa, số thứ tự các rule phía sau sẽ thay đổi. Luôn chạy `ufw status numbered` lại trước khi xóa rule tiếp theo.

---

## 9. Bảng Tổng Hợp Các Lệnh UFW

| Mục Đích | Lệnh | Ghi Chú |
|---|---|---|
| **Xem trạng thái** | `ufw status verbose` | Xem rules và chính sách mặc định |
| **Bật tường lửa** | `ufw --force enable` | Kích hoạt UFW |
| **Tắt tường lửa** | `ufw disable` | Vô hiệu hóa UFW (không xóa rules) |
| **Reset toàn bộ** | `ufw reset` | Xóa tất cả rules, đưa về mặc định |
| **Cho phép cổng** | `ufw allow <port>/tcp` | Mở cổng cho traffic TCP |
| **Chặn cổng** | `ufw deny <port>/tcp` | Đóng cổng cụ thể |
| **Rate limit** | `ufw limit <port>/tcp` | Chống brute-force (6 lần/30s) |
| **Cho phép từ IP** | `ufw allow from <IP/CIDR> to any port <port>` | Giới hạn theo nguồn |
| **Xem rules số** | `ufw status numbered` | Đánh số để quản lý |
| **Xóa rule** | `ufw delete <number>` | Xóa theo số thứ tự |

---

## 10. Thử Thách & Xác Thực (Verification)

Hãy đảm bảo tường lửa UFW đã được cấu hình đúng:

1. UFW đang ở trạng thái **active**.
2. Có rule cho phép **SSH** trên port 2222.
3. Có rule cho phép **HTTP** trên port 80.

Bấm nút **Check** bên dưới thanh điều khiển để hệ thống tự động xác thực!
