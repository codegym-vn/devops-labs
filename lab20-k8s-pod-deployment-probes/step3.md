# Bước 3: Quản Trị Cấu Hình Ứng Dụng Với ConfigMap & Secret

Một trong những nguyên tắc cốt lõi của kiến trúc điện toán đám mây (Twelve-Factor App) là **tuyệt đối không hard-code cấu hình và thông tin nhạy cảm vào mã nguồn hoặc Docker image**. Kubernetes giải quyết bài toán này bằng cách tách biệt cấu hình thành hai đối tượng độc lập: **ConfigMap** và **Secret**.

---

## 1. Phân Biệt ConfigMap Và Secret

```
┌──────────────────────────────────────────────────────────────┐
│                    NGUỒN CẤU HÌNH ĐỘNG                       │
│                                                              │
│   ┌──────────────────────────┐    ┌──────────────────────┐   │
│   │        CONFIGMAP         │    │        SECRET        │   │
│   │   (Dữ liệu phi bí mật)   │    │ (Mật khẩu, Token, CA)│   │
│   │   - APP_ENV=production   │    │ - DB_PASSWORD=***    │   │
│   │   - LOG_LEVEL=info       │    │ - API_KEY=***        │   │
│   └─────────────┬────────────┘    └──────────┬───────────┘   │
└─────────────────┼────────────────────────────┼───────────────┘
                  │                            │
                  ▼ tiêm vào Container        ▼
┌──────────────────────────────────────────────────────────────┐
│                         POD ỨNG DỤNG                         │
│   Môi trường thực thi:                                       │
│   $APP_ENV ──► "production"                                  │
│   $DB_PASSWORD ──► "SecurePassWord123!"                      │
└──────────────────────────────────────────────────────────────┘
```

1. **ConfigMap:** Lưu trữ cấu hình ứng dụng thông thường dưới dạng cặp Key-Value hoặc toàn bộ tệp cấu hình (như `nginx.conf`, `redis.conf`).
2. **Secret:** Lưu trữ dữ liệu nhạy cảm (mật khẩu, token, private key). Mặc dù được hiển thị dưới dạng chuỗi Base64 trong tệp YAML, Secret được Kubernetes giới hạn quyền truy cập qua RBAC và chỉ nạp vào bộ nhớ tạm (tmpfs) của Node khi Pod cần sử dụng.

---

## 2. Các Bước Thực Hành Hướng Dẫn

### 2.1 — Khởi tạo ConfigMap bằng lệnh trực tiếp (Imperative)

Tạo ConfigMap `app-config` chứa thông tin môi trường triển khai và mức độ ghi log:

```bash
kubectl create configmap app-config \
  --from-literal=APP_ENV=production \
  --from-literal=LOG_LEVEL=info
```{{exec}}

Kiểm tra nội dung ConfigMap vừa tạo:

```bash
kubectl describe configmap app-config
```{{exec}}

---

### 2.2 — Khởi tạo Secret lưu trữ thông tin xác thực cơ sở dữ liệu

Tạo Secret `db-secret` chứa tài khoản và mật khẩu bí mật:

```bash
kubectl create secret generic db-secret \
  --from-literal=DB_USER=postgres_admin \
  --from-literal=DB_PASSWORD=SecurePassWord123!
```{{exec}}

Xem cách Kubernetes mã hóa Base64 giá trị Secret:

```bash
kubectl get secret db-secret -o yaml
```{{exec}}

Bạn có thể giải mã ngược lại bằng lệnh `base64 -d` trên Linux:

```bash
ENCODED_PW=$(kubectl get secret db-secret -o jsonpath='{.data.DB_PASSWORD}')
echo "$ENCODED_PW" | base64 -d
echo ""
```{{exec}}

---

### 2.3 — Tiêm ConfigMap và Secret vào Pod dưới dạng Biến Môi Trường

Tạo tệp cấu hình Pod nạp cả ConfigMap và Secret vào tiến trình:

```bash
cat << 'EOF' > /root/k8s-workloads/config-demo.yaml
apiVersion: v1
kind: Pod
metadata:
  name: config-demo
  labels:
    app: config-demo
spec:
  containers:
  - name: app
    image: alpine:latest
    command: ["sleep", "3600"]
    env:
    - name: APPLICATION_ENV
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: APP_ENV
    - name: LOGGING_LEVEL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: LOG_LEVEL
    - name: DATABASE_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: DB_PASSWORD
EOF
```{{exec}}

Khởi chạy Pod:

```bash
kubectl apply -f /root/k8s-workloads/config-demo.yaml
```{{exec}}

Đợi vài giây để Pod chuyển sang `Running`:

```bash
kubectl get pod config-demo
```{{exec}}

---

### 2.4 — Xác minh giá trị biến môi trường bên trong container

Sử dụng lệnh `kubectl exec` để kiểm tra các biến môi trường thực tế bên trong container:

```bash
kubectl exec config-demo -- env | grep -E "APPLICATION_ENV|LOGGING_LEVEL|DATABASE_PASSWORD"
```{{exec}}

Các giá trị từ ConfigMap và Secret đã được giải mã và nạp trực tiếp vào môi trường thực thi của ứng dụng!

---

## 3. Bài Tập Thử Thách

> [!TIP] Hãy hoàn thành các thao tác hướng dẫn ở trên trước khi thực hiện thử thách tự lập này.

Ứng dụng của bạn chuẩn bị tích hợp với một cổng thanh toán quốc tế và cần lưu khóa bảo mật API mà không được đưa vào Git.

**Yêu cầu:**
1. Khởi tạo một đối tượng Secret kiểu Generic có tên là `api-credentials` trong namespace mặc định.
2. Secret này chứa duy nhất một cặp Key-Value với khóa là `API_KEY` và giá trị là `SuperSecretKey99`.
3. Kiểm tra và xác nhận Secret đã được tạo thành công với đúng tên khóa và giá trị mã hóa tương ứng.

**Gợi ý:**
- Sử dụng câu lệnh trực tiếp `kubectl create secret generic <tên-secret> --from-literal=<key>=<value>` như đã thực hành ở mục 2.2.
- Kiểm tra danh sách khóa bên trong bằng lệnh `kubectl describe secret api-credentials`.

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
