# Bước 4: Inject Secret An Toàn Vào Ứng Dụng Runtime

Sau khi đã có cơ chế xác thực AppRole, bài toán cuối cùng là: **Làm sao để ứng dụng nhận được thông tin mật tại thời điểm khởi chạy (Runtime) mà không cần ghi mật khẩu vào tệp `.env` hay tệp cấu hình trên đĩa cứng?**

---

## 1. Kiến Trúc Bộ Nhớ RAM (In-Memory Secret Injection)

```
┌─────────────────┐       1. Đăng nhập AppRole        ┌─────────────────┐
│                 ├──────────────────────────────────►│                 │
│                 │       2. Nhận Client Token ngắn hạn│  HASHICORP      │
│  SCRIPT KHỞI    │◄──────────────────────────────────┤     VAULT       │
│     ĐỘNG        │       3. Lấy secret qua REST API  │    SERVER       │
│                 ├──────────────────────────────────►│                 │
│                 │       4. Trả về JSON secret       │                 │
│                 │◄──────────────────────────────────┤                 │
└────────┬────────┘                                   └─────────────────┘
         │
         │ 5. Gán trực tiếp vào biến môi trường trong RAM
         ▼
┌─────────────────────────────────┐
│     ỨNG DỤNG NODE.JS RUNTIME    │
│  (Không có file .env trên đĩa)  │
└─────────────────────────────────┘
```

Mật khẩu chỉ tồn tại trong không gian bộ nhớ tiến trình (Process Memory). Khi ứng dụng tắt hoặc máy chủ khởi động lại, không có bất kỳ dấu vết nào của mật khẩu được lưu lại trên ổ đĩa.

---

## 2. Các Bước Thực Hiện

### 2.1 — Tạo mã nguồn dịch vụ thanh toán `app.js`

Tạo tệp `app.js` đọc cấu hình cơ sở dữ liệu từ các biến môi trường:

```bash
cd /root/vault-lab
cat << 'EOF' > app.js
const http = require('http');

const dbConfig = {
  user: process.env.DB_USER || 'NOT_CONFIGURED',
  password: process.env.DB_PASSWORD ? '******** (MASKED_IN_RAM)' : 'MISSING',
  host: process.env.DB_HOST || 'NOT_CONFIGURED',
  port: process.env.DB_PORT || 'NOT_CONFIGURED'
};

const server = http.createServer((req, res) => {
  if (req.url === '/db-status') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'success',
      service: 'payment-service',
      database: dbConfig,
      connected: !!process.env.DB_PASSWORD
    }, null, 2));
  } else {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('Payment Service Active\n');
  }
});

server.listen(3000, '0.0.0.0', () => {
  console.log('[INFO] Payment service running on port 3000');
  console.log('[INFO] Database User:', dbConfig.user);
  console.log('[INFO] Database Status:', dbConfig.password);
});
EOF
```{{exec}}

---

### 2.2 — Viết script tự động xác thực và nạp Secret `run-app.sh`

Tạo tệp `run-app.sh` tự động hóa toàn bộ chu trình:

```bash
cat << 'EOF' > run-app.sh
#!/bin/bash
set -e

VAULT_ADDR="http://127.0.0.1:8200"

# 1. Doc RoleID va SecretID
ROLE_ID=$(cat role_id.txt)
SECRET_ID=$(cat secret_id.txt)

echo "[VAULT] Dang xac thuc AppRole voi Vault Server..."
APP_TOKEN=$(curl -s -X POST \
  --data "{\"role_id\":\"$ROLE_ID\",\"secret_id\":\"$SECRET_ID\"}" \
  "$VAULT_ADDR/v1/auth/approle/login" | jq -r .auth.client_token)

if [ "$APP_TOKEN" == "null" ] || [ -z "$APP_TOKEN" ]; then
  echo "[ERROR] Dang nhap AppRole that bai!"
  exit 1
fi

echo "[VAULT] Lay secret tu endpoint secret/data/payment/database..."
SECRET_JSON=$(curl -s -H "X-Vault-Token: $APP_TOKEN" \
  "$VAULT_ADDR/v1/secret/data/payment/database" | jq -r .data.data)

# 2. Trich xuat cac truong vao bien RAM
export DB_USER=$(echo "$SECRET_JSON" | jq -r .username)
export DB_PASSWORD=$(echo "$SECRET_JSON" | jq -r .password)
export DB_HOST=$(echo "$SECRET_JSON" | jq -r .host)
export DB_PORT=$(echo "$SECRET_JSON" | jq -r .port)

# 3. Huy bo bien chua toan bo JSON khoi bo nho shell
unset SECRET_JSON

echo "[APP] Khoi dong ung dung voi bien moi truong da duoc inject..."
nohup node app.js > app.log 2>&1 &
sleep 2
echo "[APP] Ung dung da khoi chay thanh cong!"
EOF

chmod +x run-app.sh
```{{exec}}

---

### 2.3 — Thực thi script và kiểm tra dịch vụ

Chạy script khởi động:

```bash
./run-app.sh
```{{exec}}

Kiểm tra nhật ký ứng dụng:

```bash
cat app.log
```{{exec}}

Gửi yêu cầu tới endpoint `/db-status` để xác nhận ứng dụng đã nhận diện đầy đủ thông tin bí mật từ Vault:

```bash
curl -s http://localhost:3000/db-status
```{{exec}}

Kết quả JSON trả về:
* `"status": "success"`
* `"user": "payment_user"`
* `"connected": true`

Kiểm tra thư mục làm việc: Không hề có bất kỳ tệp mật khẩu nào tồn tại trên đĩa cứng. Toàn bộ thông tin mật được bảo vệ tập trung và an toàn tuyệt đối bên trong Vault Server.

Nhấn **Check** để hoàn thành Bước 4!
