# Bước 3: Tự Động Hóa Giám Sát Sức Khỏe & Thăng Cấp (Promotion) Lên Cụm

Khi phiên bản Canary đã tiếp nhận lưu lượng thực tế, bước tiếp theo trong chu trình CI/CD là tự động đánh giá sức khỏe của ứng dụng. Nếu tỷ lệ lỗi nằm dưới ngưỡng cho phép, hệ thống sẽ thực hiện **Thăng cấp (Promotion)** — biến phiên bản mới thành phiên bản chính thức phục vụ 100% người dùng.

---

## 1. Cổng Kiểm Soát Chất Lượng (Quality Gate)

Quy trình tự động hóa kiểm tra sức khỏe:
1. Gửi liên tục một loạt các yêu cầu (ví dụ 30 requests) tới Service.
2. Đếm số lượng phản hồi HTTP 200 (thành công) và các phản hồi lỗi (HTTP 5xx hoặc mất kết nối).
3. Tính toán tỷ lệ lỗi:
   * Nếu Tỷ lệ lỗi <= 5%: Đánh giá đạt chuẩn, cho phép thăng cấp.
   * Nếu Tỷ lệ lỗi > 5%: Cảnh báo nguy hiểm, từ chối thăng cấp và dừng pipeline.

---

## 2. Các Bước Thực Hiện

### 2.1 — Viết và chạy script kiểm tra tỷ lệ lỗi

Tạo tệp script tự động hóa `verify-canary.sh`:

```bash
cd /root/canary-lab
cat << 'EOF' > verify-canary.sh
#!/bin/bash
TOTAL=20
SUCCESS=0
ERROR=0

echo "[INFO] Dang kiem tra ty le phan hoi cua web-service ($TOTAL requests)..."

for i in $(seq 1 $TOTAL); do
  CODE=$(kubectl run check-$i --image=curlimages/curl --restart=Never --rm -q -- \
    curl -s -o /dev/null -w "%{http_code}" http://web-service/ 2>/dev/null || echo "500")

  if [ "$CODE" -eq 200 ]; then
    SUCCESS=$((SUCCESS + 1))
  else
    ERROR=$((ERROR + 1))
  fi
  sleep 0.1
done

ERROR_RATE=$(( ERROR * 100 / TOTAL ))
echo "[INFO] Tong: $TOTAL | Thanh cong: $SUCCESS | Loi: $ERROR | Ty le loi: ${ERROR_RATE}%"

if [ "$ERROR_RATE" -gt 5 ]; then
  echo "[FAIL] Ty le loi vuot nguong 5%! Tu choi thang cap."
  exit 1
else
  echo "[PASS] Phien ban Canary dat chuan an toan! Cho phep thang cap."
  exit 0
fi
EOF

chmod +x verify-canary.sh
```{{exec}}

Thực thi script kiểm tra:

```bash
./verify-canary.sh
```{{exec}}

Script sẽ in ra kết quả `[PASS] Phien ban Canary dat chuan an toan!` với tỷ lệ lỗi 0%.

---

### 2.2 — Thực hiện thăng cấp phiên bản mới lên Deployment Stable

Khi phiên bản v2.0 đã được kiểm chứng ổn định, ta cập nhật `deployment-stable.yaml` để nâng cấp toàn bộ cụm lên phiên bản v2.0 và mở rộng quy mô thành **4 Pods**:

```bash
cat << 'EOF' > deployment-stable.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-stable
spec:
  replicas: 4
  selector:
    matchLabels:
      app: web-app
      track: stable
  template:
    metadata:
      labels:
        app: web-app
        track: stable
    spec:
      containers:
        - name: app
          image: nginxdemos/hello:plain-text
          ports:
            - containerPort: 80
          env:
            - name: APP_VERSION
              value: "v2.0-stable"
EOF
```{{exec}}

Áp dụng bản cập nhật lên cụm:

```bash
kubectl apply -f deployment-stable.yaml
```{{exec}}

Theo dõi quá trình cập nhật cuốn chiếu (Rolling Update) của nhánh Stable:

```bash
kubectl rollout status deployment/web-stable
```{{exec}}

---

### 2.3 — Thu hồi Deployment Canary

Khi toàn bộ 4 Pod của `web-stable` đã hoạt động ổn định trên phiên bản v2.0, ta tiến hành xóa bỏ Deployment Canary để giải phóng tài nguyên:

```bash
kubectl delete -f deployment-canary.yaml
```{{exec}}

Kiểm tra lại danh sách Pod:

```bash
kubectl get pods -l app=web-app -L track
```{{exec}}

Lúc này, toàn bộ 4 Pod đang chạy đều thuộc `web-stable` với phiên bản mới. Quá trình chuyển giao phiên bản hoàn thành trọn vẹn mà không làm rớt bất kỳ kết nối nào của người dùng.

Nhấn **Check** để hoàn thành Bước 3!
