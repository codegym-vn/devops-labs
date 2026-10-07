# Bước 1: Khởi Tạo Vault Server & Thao Tác Với KV-v2 Secret Engine

Trong bước đầu tiên, bạn sẽ làm quen với Vault CLI, kích hoạt **Key-Value Secret Engine phiên bản 2 (KV-v2)** và thực hành lưu trữ, cập nhật secret có quản lý phiên bản (Versioned Secrets).

---

## 1. Kiểm Tra Trạng Thái Vault Server

Vault Server đã được hệ thống khởi chạy sẵn ở chế độ dev mode trên cổng 8200. Kiểm tra trạng thái của server:

```bash
cd /root/vault-lab
vault status
```{{exec}}

Quan sát các thông số quan trọng:
* **Initialized: true:** Vault đã được khởi tạo.
* **Sealed: false:** Vault đang ở trạng thái Unsealed (đã mở khóa và sẵn sàng giải mã/mã hóa dữ liệu).
* **Storage Type: inmem:** Bộ lưu trữ tạm thời trong bộ nhớ phục vụ thực hành.

---

## 2. Kích Hoạt KV Secret Engine Phiên Bản 2

KV-v2 cho phép lưu trữ các cặp khóa - giá trị tùy ý dưới dạng cây thư mục và tự động lưu lại lịch sử các phiên bản của secret.

Kích hoạt engine tại đường dẫn `secret/`:

```bash
vault secrets enable -version=2 -path=secret kv 2>/dev/null || echo "[INFO] Engine secret/ da duoc bat san!"
```{{exec}}

Liệt kê danh sách các Secret Engine đang hoạt động:

```bash
vault secrets list
```{{exec}}

---

## 3. Thao Tác Ghi & Đọc Secret Có Quản Lý Phiên Bản

Lưu thông tin xác thực cơ sở dữ liệu của dịch vụ thanh toán (`payment`) vào đường dẫn `secret/payment/database`:

```bash
vault kv put secret/payment/database username="payment_user" password="VaultSuperSecretPass2026" host="postgres.prod.internal" port="5432"
```{{exec}}

Đọc secret vừa lưu trữ:

```bash
vault kv get secret/payment/database
```{{exec}}

Quan sát phần **Metadata**: Secret đang ở phiên bản `version 1`.

Bây giờ, mô phỏng quy trình định kỳ đổi mật khẩu (Password Rotation): Thực hiện ghi đè mật khẩu mới vào cùng đường dẫn:

```bash
vault kv put secret/payment/database username="payment_user" password="RotatedNewPassword2026" host="postgres.prod.internal" port="5432"
```{{exec}}

Kiểm tra lại:

```bash
vault kv get secret/payment/database
```{{exec}}

Metadata lúc này hiển thị `version 2`. Với KV-v2, bạn hoàn toàn có thể đọc lại phiên bản cũ trong trường hợp cần đối soát:

```bash
vault kv get -version=1 secret/payment/database
```{{exec}}

Nhấn **Check** để hoàn thành Bước 1!
