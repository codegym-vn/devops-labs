# Bước 1: SSH Hardening - Key-Based Auth & Gia Cố sshd_config

SSH là dịch vụ bị tấn công nhiều nhất trên bất kỳ server Linux nào kết nối Internet. Các bot tự động liên tục quét port 22 và thử brute-force password. Trong bước này, bạn sẽ triển khai các biện pháp gia cố SSH theo chuẩn bảo mật production.

> **Lưu ý môi trường:** Hệ thống Killercoda đã tự động cài đặt sẵn `openssh-server`, `ufw` và `netcat` ở chế độ nền. Bạn có thể bắt đầu gõ lệnh ngay.

---

## 1. Kiểm Tra Trạng Thái SSH Hiện Tại

Xem SSH daemon có đang chạy không:

```bash
systemctl status ssh --no-pager
```{{exec}}

Kiểm tra SSH đang lắng nghe trên cổng nào:

```bash
ss -tlpn | grep ssh
```{{exec}}

Bạn sẽ thấy SSH đang listen trên port `22` — đây là port mặc định mà mọi bot scanner đều nhắm tới.

---

## 2. Tạo SSH Key Pair (Ed25519)

Thay vì dùng password dễ bị brute-force, xác thực bằng **SSH Key** an toàn hơn nhiều lần vì khóa riêng tư (private key) không bao giờ được gửi qua mạng.

### Tại sao chọn Ed25519 thay vì RSA?

| Đặc Tính | RSA (4096-bit) | Ed25519 |
|---|---|---|
| **Độ dài khóa** | 4096 bit | 256 bit |
| **Tốc độ ký/xác minh** | Chậm hơn | Nhanh hơn đáng kể |
| **Bảo mật** | Tương đương | Tương đương (Elliptic Curve) |
| **Kích thước public key** | ~800 ký tự | ~68 ký tự |
| **Khuyến nghị** | Vẫn an toàn | Được ưu tiên sử dụng |

Tạo cặp khóa Ed25519:

```bash
ssh-keygen -t ed25519 -f /root/.ssh/lab_key -N "" -C "devops-lab"
```{{exec}}

Giải thích tham số:
- `-t ed25519`: Loại thuật toán khóa.
- `-f /root/.ssh/lab_key`: Đường dẫn lưu khóa riêng tư.
- `-N ""`: Không đặt passphrase (cho mục đích lab).
- `-C "devops-lab"`: Comment gắn vào khóa để nhận diện.

Xem khóa công khai vừa tạo:

```bash
cat /root/.ssh/lab_key.pub
```{{exec}}

### Thêm khóa công khai vào danh sách được phép đăng nhập

```bash
cat /root/.ssh/lab_key.pub >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
```{{exec}}

Kiểm tra đăng nhập bằng key (trên chính máy này):

```bash
ssh -i /root/.ssh/lab_key -o StrictHostKeyChecking=no localhost whoami
```{{exec}}

Kết quả trả về `root` nghĩa là xác thực bằng key đã hoạt động.

---

## 3. Gia Cố File Cấu Hình sshd_config

File `/etc/ssh/sshd_config` kiểm soát toàn bộ hành vi của SSH daemon. Hãy xem cấu hình mặc định trước:

```bash
grep -E "^#?(Port|PermitRootLogin|PasswordAuthentication|PubkeyAuthentication|MaxAuthTries|ClientAlive)" /etc/ssh/sshd_config
```{{exec}}

### Áp dụng cấu hình hardened

Sửa trực tiếp file `/etc/ssh/sshd_config` bằng các lệnh `sed`. Cách này đảm bảo hoạt động trên mọi phiên bản Ubuntu:

**Đổi port SSH từ 22 sang 2222:**

```bash
sed -i 's/^#\?Port 22$/Port 2222/' /etc/ssh/sshd_config
```{{exec}}

**Tắt xác thực bằng password, chỉ cho phép key:**

```bash
sed -i 's/^#\?PasswordAuthentication yes$/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
```{{exec}}

**Hạn chế đăng nhập root (chỉ cho phép bằng key):**

```bash
sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
```{{exec}}

**Giới hạn số lần thử sai và session timeout:**

```bash
sed -i 's/^#\?MaxAuthTries .*/MaxAuthTries 3/' /etc/ssh/sshd_config
sed -i 's/^#\?ClientAliveInterval .*/ClientAliveInterval 300/' /etc/ssh/sshd_config
sed -i 's/^#\?ClientAliveCountMax .*/ClientAliveCountMax 2/' /etc/ssh/sshd_config
```{{exec}}

Kiểm tra các thay đổi đã được áp dụng đúng:

```bash
grep -E "^(Port|PasswordAuthentication|PubkeyAuthentication|PermitRootLogin|MaxAuthTries|ClientAlive)" /etc/ssh/sshd_config
```{{exec}}

### Bảng giải thích các chỉ thị hardening

| Chỉ Thị | Giá Trị | Ý Nghĩa |
|---|---|---|
| `Port 2222` | Đổi từ 22 | Giảm 99% bot scan tự động (chúng chỉ quét port 22) |
| `PasswordAuthentication no` | Tắt password | Chặn hoàn toàn brute-force attack |
| `PubkeyAuthentication yes` | Bật key auth | Chỉ ai có private key mới đăng nhập được |
| `PermitRootLogin prohibit-password` | Hạn chế root | Root chỉ login được bằng key, không bằng password |
| `MaxAuthTries 3` | Giới hạn 3 lần | Ngắt kết nối sau 3 lần xác thực sai |
| `ClientAliveInterval 300` | 5 phút | Gửi probe mỗi 5 phút để phát hiện session idle |
| `ClientAliveCountMax 2` | 2 lần probe | Ngắt kết nối nếu 2 lần probe không có phản hồi |

---

## 4. Kiểm Tra Cú Pháp và Restart SSH

Luôn kiểm tra cú pháp trước khi restart (tương tự `nginx -t`):

```bash
sshd -t
```{{exec}}

Nếu không có lỗi, restart SSH daemon:

```bash
systemctl restart ssh
```{{exec}}

Kiểm tra SSH đã chuyển sang port 2222:

```bash
ss -tlpn | grep ssh
```{{exec}}

Bạn sẽ thấy SSH đã lắng nghe trên port `2222` thay vì `22`.

### Kiểm tra kết nối SSH qua port mới

```bash
ssh -i /root/.ssh/lab_key -p 2222 -o StrictHostKeyChecking=no localhost whoami
```{{exec}}

---

## 5. Thử Thách & Xác Thực (Verification)

Hãy đảm bảo SSH của bạn đã được gia cố đúng cách:

1. SSH đang lắng nghe trên **port 2222** (không còn port 22).
2. Chỉ thị `PasswordAuthentication` đã được đặt thành `no`.

Bấm nút **Check** bên dưới thanh điều khiển để hệ thống tự động xác thực!
