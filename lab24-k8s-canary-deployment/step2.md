# Bước 2: Triển Khai Phiên Bản Thử Nghiệm Canary v2 & Phân Bổ Lưu Lượng

Trong bước này, bạn sẽ triển khai phiên bản thử nghiệm mới (v2.0) song song với phiên bản hiện tại. Thay vì thay thế toàn bộ, bạn chỉ cấp phát **1 Pod** Canary bên cạnh **3 Pod** Stable sẵn có.

---

## 1. Tính Toán Tỷ Lệ Lưu Lượng (Traffic Weighting)

Tỷ lệ phân phối lưu lượng giữa các phiên bản được tính như sau:
* **Tỷ lệ lưu lượng Canary** = Số Pod Canary / Tổng số Pod = 1 / (3 + 1) = 1/4 = **25%**
* **Tỷ lệ lưu lượng Stable** = Số Pod Stable / Tổng số Pod = 3 / (3 + 1) = 3/4 = **75%**

Nếu phiên bản mới phát sinh lỗi, tối đa chỉ 25% người dùng gặp sự cố trong thời gian thử nghiệm, và ta có thể khắc phục ngay mà không ảnh hưởng tới 75% còn lại.

---

## 2. Các Bước Thực Hiện

### 2.1 — Triển khai Deployment Canary v2

Tạo tệp manifest `deployment-canary.yaml` với nhãn `track: canary`:

```bash
cd /root/canary-lab
cat << 'EOF' > deployment-canary.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-canary
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-app
      track: canary
  template:
    metadata:
      labels:
        app: web-app
        track: canary
    spec:
      containers:
        - name: app
          image: nginxdemos/hello:plain-text
          ports:
            - containerPort: 80
          env:
            - name: APP_VERSION
              value: "v2.0-canary"
EOF
```{{exec}}

Triển khai phiên bản Canary lên cụm:

```bash
kubectl apply -f deployment-canary.yaml
```{{exec}}

Chờ Pod của Canary chuyển sang trạng thái Ready:

```bash
kubectl rollout status deployment/web-canary
```{{exec}}

---

### 2.2 — Quan sát phân bổ Endpoints trên Service

Kiểm tra danh sách toàn bộ các Pod đang mang nhãn `app=web-app`:

```bash
kubectl get pods -l app=web-app -L track
```{{exec}}

Bạn sẽ thấy 4 Pod cùng chạy, trong đó có 3 Pod mang nhãn `track=stable` và 1 Pod mang nhãn `track=canary`.

Kiểm tra danh sách IP đích của Service:

```bash
kubectl get endpoints web-service
```{{exec}}

Service `web-service` đã tự động bổ sung địa chỉ IP của Pod Canary vào danh sách tải. Tổng số Endpoints lúc này là 4.

---

### 2.3 — Đo lường tỷ lệ phân bổ lưu lượng thực tế

Chạy một Pod tạm gửi 20 yêu cầu liên tục tới `web-service` và in ra tên Pod tiếp nhận yêu cầu:

```bash
kubectl run traffic-tester --image=curlimages/curl --restart=Never -it --rm -- \
  sh -c '
    echo "Dang gui 20 yeu cau toi web-service..."
    for i in $(seq 1 20); do
      pod=$(curl -s http://web-service/ | grep "Server name:" | awk "{print \$3}")
      echo "Yeu cau $i duoc xu ly boi Pod: $pod"
      sleep 0.2
    done
  '
```{{exec}}

Quan sát danh sách Pod phản hồi: Các yêu cầu được phân bổ đều cho cả 4 Pod, chứng minh phiên bản Canary đã tiếp nhận một phần lưu lượng trực tiếp từ người dùng mà không cần can thiệp cấu hình Ingress phức tạp.

Nhấn **Check** để hoàn thành Bước 2!
