# Bước 2: SSH Port Forwarding - Đường Hầm Mã Hóa & Tunnel

Trong thực tế DevOps, nhiều dịch vụ nội bộ (database, admin panel, monitoring) chỉ lắng nghe trên `127.0.0.1` hoặc mạng private và **không được expose trực tiếp ra Internet**. SSH Port Forwarding cho phép bạn tạo một **đường hầm mã hóa** (tunnel) để truy cập các dịch vụ này một cách an toàn.

---

## 1. Port Forwarding Là Gì?

SSH Tunnel tạo một kênh truyền mã hóa giữa máy local và server remote, cho phép chuyển tiếp traffic qua kênh này:

```text
[Laptop DevOps]                         [Server Production]
      |                                       |
      |  ====== SSH Tunnel (mã hóa) ======   |
      |                                       |
 localhost:9090  ─────────────────────>  localhost:8080
 (Truy cập tại đây)                    (Database/API nội bộ)
```

### Use Case Thực Tế Trong DevOps

- **Truy cập database nội bộ** (PostgreSQL port 5432) từ laptop mà không cần expose ra Internet.
- **Debug ứng dụng trên server** bằng cách tunnel port debug về máy local.
- **Truy cập admin panel** (Grafana, Kibana, Jenkins) nằm sau firewall.

---

## 2. Local Port Forwarding (`-L`)

**Hướng**: Chuyển tiếp traffic từ **máy local** qua SSH tunnel tới **dịch vụ trên server**.

```text
Cú pháp: ssh -L <local_port>:<target_host>:<target_port> user@ssh_server
```

### Thực hành: Tạo mock service và tunnel

Khởi chạy một web service giả lập trên port 8080 (mô phỏng API nội bộ):

```bash
python3 -m http.server 8080 --bind 127.0.0.1 > /dev/null 2>&1 &
```{{exec}}

Kiểm tra service đang chạy:

```bash
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8080
```{{exec}}

Bây giờ, tạo SSH tunnel chuyển tiếp port 9090 (local) → 8080 (server):

```bash
ssh -L 9090:127.0.0.1:8080 -N -f -p 2222 -i /root/.ssh/lab_key -o StrictHostKeyChecking=no localhost
```{{exec}}

Giải thích tham số:
- `-L 9090:127.0.0.1:8080`: Chuyển tiếp port 9090 local → port 8080 trên server.
- `-N`: Không mở shell (chỉ tạo tunnel).
- `-f`: Chạy ngầm trong nền (background).
- `-p 2222`: Kết nối SSH qua port 2222 (đã đổi ở Bước 1).

Truy cập service **qua tunnel**:

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:9090
```{{exec}}

Kết quả `200` — bạn đã truy cập thành công service nội bộ (port 8080) thông qua SSH tunnel (port 9090)!

### Kiểm tra tunnel đang hoạt động

```bash
ss -tlpn | grep 9090
```{{exec}}

---

## 3. Remote Port Forwarding (`-R`)

**Hướng**: Ngược lại — chuyển tiếp traffic từ **server remote** về **dịch vụ trên máy local**.

```text
Cú pháp: ssh -R <remote_port>:<local_host>:<local_port> user@ssh_server
```

```text
[Server Remote]                         [Laptop DevOps]
      |                                       |
 remote:3000  <───── SSH Tunnel ─────  localhost:3000
 (Ai truy cập server                  (App React/Node đang
  port 3000 sẽ thấy                    chạy trên laptop)
  ứng dụng của bạn)
```

### Use Case

- **Expose local dev server** ra Internet để đồng nghiệp hoặc khách hàng xem preview.
- **Webhook testing**: Cho phép dịch vụ bên ngoài (GitHub, Stripe) gọi tới ứng dụng đang chạy trên laptop.

> **Lưu ý:** Để Remote Forwarding hoạt động từ bên ngoài, cần thêm `GatewayPorts yes` vào sshd_config trên server remote.

---

## 4. Dynamic Port Forwarding / SOCKS Proxy (`-D`)

**Hướng**: Biến SSH server thành một **SOCKS5 Proxy** — mọi traffic đi qua proxy đều được mã hóa.

```text
Cú pháp: ssh -D <local_port> user@ssh_server
```

```text
[Laptop DevOps]                              [SSH Server]
      |                                            |
 Browser/curl ──> SOCKS5 (localhost:1080) ──> Internet
                  (Mã hóa SSH)                (Truy cập từ IP của server)
```

### Use Case

- **Truy cập tài nguyên nội bộ** từ xa mà không cần VPN.
- **Bypass firewall** khi làm việc tại mạng công ty chặn một số website.

Tạo SOCKS proxy trên port 1080:

```bash
ssh -D 1080 -N -f -p 2222 -i /root/.ssh/lab_key -o StrictHostKeyChecking=no localhost
```{{exec}}

Kiểm tra proxy hoạt động bằng `curl` với tham số `--socks5`:

```bash
curl --socks5 localhost:1080 -s -o /dev/null -w "%{http_code}" http://example.com
```{{exec}}

---

## 5. Bảng Tổng Hợp 3 Loại Port Forwarding

| Loại | Flag | Hướng | Cú Pháp | Use Case DevOps |
|---|---|---|---|---|
| **Local** | `-L` | Local → Remote | `-L 9090:host:8080` | Truy cập DB/API nội bộ từ laptop |
| **Remote** | `-R` | Remote → Local | `-R 3000:localhost:3000` | Expose dev server ra Internet |
| **Dynamic** | `-D` | SOCKS Proxy | `-D 1080` | Duyệt web/API qua tunnel mã hóa |

---

## 6. Thử Thách & Xác Thực (Verification)

Hãy đảm bảo SSH tunnel Local Port Forwarding đang hoạt động:

1. Service mock đang chạy trên port 8080.
2. Tunnel đang chuyển tiếp từ port 9090 → 8080.
3. `curl http://localhost:9090` trả về HTTP 200.

Bấm nút **Check** bên dưới thanh điều khiển để hệ thống tự động xác thực!
