# Bước 2: Triển Khai Ứng Dụng Quy Mô Lớn Với Deployment & Tự Phục Hồi

Trong môi trường thực tế, nếu bạn tạo Pod đơn lẻ (thường gọi là *Bare Pod*), khi Node chứa Pod đó bị sập nguồn hoặc Pod bị dừng ngoài ý muốn, Kubernetes sẽ **không bao giờ** tự động khởi tạo lại Pod đó. Để giải quyết bài toán tính sẵn sàng cao, mở rộng quy mô và cập nhật không gián đoạn, Kubernetes cung cấp đối tượng **Deployment**.

---

## 1. Mối Quan Hệ Giữa Deployment, ReplicaSet và Pod

```
┌──────────────────────────────────────────────────────────────┐
│                    DEPLOYMENT (web-deploy)                   │
│   Quản lý chiến lược nâng cấp (RollingUpdate) & Lịch sử     │
└──────────────────────────────┬───────────────────────────────┘
                               │ điều khiển
                               ▼
┌──────────────────────────────────────────────────────────────┐
│                   REPLICASET (web-deploy-xxx)                │
│   Đảm bảo duy trì đúng số lượng bản sao (Replicas)          │
└──────────────┬───────────────┼───────────────┬───────────────┘
               │               │               │
               ▼               ▼               ▼
         ┌───────────┐   ┌───────────┐   ┌───────────┐
         │   Pod 1   │   │   Pod 2   │   │   Pod 3   │
         │ (Running) │   │ (Running) │   │ (Running) │
         └───────────┘   └───────────┘   └───────────┘
```

* **Vòng lặp tự đối chiếu (Reconciliation Loop):** Bộ điều khiển liên tục so sánh giữa **Desired State** (số bản sao mong muốn khai báo trong YAML) và **Actual State** (số Pod thực tế đang sống trên cụm). Bất kỳ khi nào có độ lệch (ví dụ 1 Pod bị xóa), hệ thống sẽ lập tức can thiệp để đưa Actual State khớp với Desired State.

---

## 2. Các Bước Thực Hành Hướng Dẫn

### 2.1 — Khởi tạo tệp khai báo Deployment

Tạo tệp cấu hình triển khai ứng dụng `web-deploy` với 3 bản sao (`replicas: 3`):

```bash
cat << 'EOF' > /root/k8s-workloads/web-deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deploy
  labels:
    app: web-deploy
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-deploy
  template:
    metadata:
      labels:
        app: web-deploy
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 100m
            memory: 128Mi
EOF
```{{exec}}

Áp dụng cấu hình vào cụm:

```bash
kubectl apply -f /root/k8s-workloads/web-deploy.yaml
```{{exec}}

---

### 2.2 — Kiểm tra Deployment, ReplicaSet và các Pods tương ứng

Xem trạng thái Deployment:

```bash
kubectl get deployments
```{{exec}}

Xem ReplicaSet trung gian được tự động tạo ra:

```bash
kubectl get replicasets
```{{exec}}

Liệt kê toàn bộ các Pods thuộc nhãn `app=web-deploy`:

```bash
kubectl get pods -l app=web-deploy -o wide
```{{exec}}

Bạn sẽ thấy 3 Pods được Kube-scheduler tự động phân phối đều trên cả các node sẵn sàng trong cụm.

---

### 2.3 — Kiểm chứng cơ chế tự phục hồi (Self-Healing)

Lấy tên của 1 Pod bất kỳ trong Deployment và tiến hành xóa thủ công:

```bash
TARGET_POD=$(kubectl get pods -l app=web-deploy -o jsonpath='{.items[0].metadata.name}')
echo "Chuan bi tieu diet Pod: $TARGET_POD"
kubectl delete pod $TARGET_POD
```{{exec}}

Quan sát danh sách Pod ngay lập tức:

```bash
kubectl get pods -l app=web-deploy
```{{exec}}

> [!NOTE]
> Bạn sẽ nhận thấy Pod cũ bị `Terminating` hoặc đã biến mất, nhưng một Pod hoàn toàn mới đã được ReplicaSet tự động sinh ra ngay tức khắc để bảo toàn đúng 3 bản sao!

---

### 2.4 — Mở rộng quy mô tức thì (Scale Out)

Thử nghiệm mở rộng quy mô Deployment lên 5 bản sao:

```bash
kubectl scale deployment web-deploy --replicas=5
```{{exec}}

Theo dõi quá trình khởi tạo thêm 2 Pod mới:

```bash
kubectl rollout status deployment web-deploy
```{{exec}}

Kiểm tra lại số lượng Pod:

```bash
kubectl get pods -l app=web-deploy
```{{exec}}

---

## 3. Bài Tập Thử Thách

> [!TIP] Hãy hoàn thành các thao tác hướng dẫn ở trên trước khi thực hiện thử thách tự lập này.

Sau giai đoạn cao điểm lưu lượng truy cập, quản trị viên cần thu hẹp quy mô hạ tầng để tối ưu hóa chi phí máy chủ.

**Yêu cầu:**
1. Thu hẹp quy mô của Deployment `web-deploy` về đúng **2 bản sao** (`replicas: 2`).
2. Xác nhận rằng số lượng Pod đang chạy thuộc Deployment `web-deploy` hiển thị đúng trạng thái `2/2` trong danh sách kiểm tra.

**Gợi ý:**
- Vận dụng câu lệnh điều chỉnh quy mô `kubectl scale` kết hợp chỉ định số lượng bản sao mong muốn (`--replicas=...`) cho Deployment `web-deploy`.
- Kiểm tra lại bằng lệnh `kubectl get deployment web-deploy` để xác nhận cột `READY` và `UP-TO-DATE` đều đạt con số `2/2`.

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
