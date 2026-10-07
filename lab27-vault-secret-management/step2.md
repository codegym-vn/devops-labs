# Bước 2: Thiết Lập Phân Quyền Least Privilege Với Vault Policy

Trong môi trường Production, tuyệt đối không được cấp `root token` cho ứng dụng hoặc pipeline CI/CD. Nguyên tắc an ninh bắt buộc là **Đặc quyền tối thiểu (Least Privilege)**: Dịch vụ `payment` chỉ được phép đọc secret của chính nó, không có quyền chỉnh sửa, và hoàn toàn bị cấm truy cập vào secret của các dịch vụ khác (ví dụ: lương thưởng, người dùng...).

Quyền hạn trong Vault được định nghĩa bằng **Vault Policy** viết bằng ngôn ngữ HCL (HashiCorp Configuration Language).

---

## 1. Lưu Ý Về Đường Dẫn KV-v2 Trong Policy

Với KV Secret Engine phiên bản 2, cấu trúc đường dẫn API được chia thành hai phần:
* `secret/data/<path>`: Chứa nội dung dữ liệu thực tế của secret.
* `secret/metadata/<path>`: Chứa thông tin các phiên bản, thời điểm tạo.

Do đó, khi viết policy cho phép đọc secret, ta cần khai báo quyền `read` trên đường dẫn có chứa chữ `data/`.

---

## 2. Các Bước Thực Hiện

### 2.1 — Viết tệp chính sách `payment-policy.hcl`

Tạo tệp policy chỉ cho phép đọc dữ liệu thuộc tiền tố `secret/data/payment/*`:

```bash
cd /root/vault-lab
cat << 'EOF' > payment-policy.hcl
# Cho phep doc noi dung secret cua payment service
path "secret/data/payment/*" {
  capabilities = ["read"]
}

# Cho phep liet ke metadata cua payment service
path "secret/metadata/payment/*" {
  capabilities = ["list", "read"]
}
EOF
```{{exec}}

---

### 2.2 — Đăng ký Policy vào Vault Server

Nạp tệp chính sách vào Vault với tên `payment-policy`:

```bash
vault policy write payment-policy payment-policy.hcl
```{{exec}}

Kiểm tra nội dung chính sách đã lưu trên hệ thống:

```bash
vault policy read payment-policy
```{{exec}}

---

### 2.3 — Thử nghiệm kiểm soát quyền hạn bằng Token hạn chế

Tạo một token tạm thời được gắn với chính sách `payment-policy`:

```bash
TEST_TOKEN=$(vault token create -policy="payment-policy" -field=token)
echo "Token thu nghiem: $TEST_TOKEN"
```{{exec}}

Tạo một secret nhạy cảm của dịch vụ nhân sự (HR) bằng quyền root để thử nghiệm:

```bash
vault kv put secret/hr/salaries ceo_salary="500000USD"
```{{exec}}

Bây giờ, sử dụng `TEST_TOKEN` (chỉ có quyền `payment-policy`) để đọc secret của `payment`:

```bash
VAULT_TOKEN="$TEST_TOKEN" vault kv get secret/payment/database
```{{exec}}

Kết quả: Đọc dữ liệu thành công.

Tiếp tục sử dụng `TEST_TOKEN` để cố tình đọc lén dữ liệu của dịch vụ nhân sự:

```bash
VAULT_TOKEN="$TEST_TOKEN" vault kv get secret/hr/salaries
```{{exec}}

Kết quả trả về: `Error reading secret/data/hr/salaries: Code: 403. Errors: * 1 error occurred: * permission denied`.

Vault đã chặn đứng hành vi truy cập trái phép, bảo vệ tính riêng tư giữa các dịch vụ.

Nhấn **Check** để hoàn thành Bước 2!
