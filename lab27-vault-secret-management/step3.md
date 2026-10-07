# Bước 3: Cấu Hình Cơ Chế Xác Thực AppRole Cho CI/CD Pipeline

Trong khi con người đăng nhập vào Vault bằng tài khoản SSO hoặc Username/Password, các hệ thống tự động (máy chủ ứng dụng, Kubernetes Pod, CI/CD Runner) cần một cơ chế xác thực chuyên biệt: **AppRole Authentication**.

---

## 1. Nguyên Lý Cặp Khóa RoleID & SecretID

Cơ chế AppRole hoạt động tương tự như xác thực 2 lớp dành cho máy móc:

```
┌─────────────────────────────────┐
│     CI/CD RUNNER HOẶC SERVER    │
├─────────────────────────────────┤
│ • RoleID   (Định danh dịch vụ)  │───┐
│ • SecretID (Mật mã dùng một lần)│   │  POST /v1/auth/approle/login
└─────────────────────────────────┘   │  (Gửi RoleID + SecretID)
                                      ▼
                      ┌───────────────────────────────┐
                      │    HASHICORP VAULT SERVER     │
                      ├───────────────────────────────┤
                      │ 1. Xác thực cặp khóa hợp lệ   │
                      │ 2. Cấp Client Token ngắn hạn  │
                      │    gắn với policy tương ứng   │
                      └───────────────┬───────────────┘
                                      │
                                      ▼ Trả về Client Token có TTL (ví dụ: 60 phút)
                      ┌───────────────────────────────┐
                      │ Dùng Token lấy secret & chạy  │
                      └───────────────────────────────┘
```

1. **RoleID:** Định danh công khai của ứng dụng (có thể cấu hình trong mã nguồn hoặc file cấu hình).
2. **SecretID:** Khóa bí mật động, có thời hạn sống (TTL), được sinh riêng và inject vào runner qua biến bảo mật của CI/CD (GitHub Secrets).

---

## 2. Các Bước Thực Hiện

### 2.1 — Kích hoạt phương thức xác thực AppRole

Kích hoạt engine xác thực AppRole trên Vault Server:

```bash
cd /root/vault-lab
vault auth enable approle 2>/dev/null || echo "[INFO] AppRole da duoc bat san!"
```{{exec}}

Kiểm tra danh sách phương thức xác thực:

```bash
vault auth list
```{{exec}}

---

### 2.2 — Khởi tạo Role cho dịch vụ Payment

Tạo một role có tên `payment-role`, gắn với chính sách `payment-policy` đã tạo ở Bước 2, và giới hạn thời gian sống của token là 60 phút:

```bash
vault write auth/approle/role/payment-role \
  secret_id_ttl=60m \
  token_ttl=60m \
  token_max_ttl=120m \
  policies="payment-policy"
```{{exec}}

---

### 2.3 — Trích xuất RoleID và sinh SecretID

Lấy RoleID của dịch vụ:

```bash
vault read -field=role_id auth/approle/role/payment-role/role-id > role_id.txt
cat role_id.txt
```{{exec}}

Sinh một SecretID mới cho phiên làm việc của pipeline:

```bash
vault write -f -field=secret_id auth/approle/role/payment-role/secret-id > secret_id.txt
cat secret_id.txt
```{{exec}}

---

### 2.4 — Thực hiện đăng nhập bằng AppRole

Mô phỏng thao tác của CI/CD Runner: Sử dụng cặp `RoleID` và `SecretID` để gửi yêu cầu đăng nhập tới endpoint `auth/approle/login`:

```bash
ROLE_ID=$(cat role_id.txt)
SECRET_ID=$(cat secret_id.txt)

APP_TOKEN=$(vault write -field=token auth/approle/login role_id="$ROLE_ID" secret_id="$SECRET_ID")
echo "Client Token nhan duoc: $APP_TOKEN"
```{{exec}}

Kiểm tra thông tin chi tiết của token vừa được cấp:

```bash
VAULT_TOKEN="$APP_TOKEN" vault token lookup
```{{exec}}

Quan sát trường `policies`: Token này được cấp đúng quyền `payment-policy` và có thời hạn tự hủy sau 3600 giây (60 phút).

Nhấn **Check** để hoàn thành Bước 3!
