# Bước 2: Triển Khai Ứng Dụng Có Trạng Thái Với StatefulSet Và Headless Service

Trong khi **Deployment** được thiết kế hoàn hảo cho các ứng dụng phi trạng thái (Stateless như Web API, Nginx frontend — nơi các Pod hoàn toàn giống hệt nhau và có thể thay thế lẫn nhau bất cứ lúc nào), thì các hệ thống lưu trữ dữ liệu (Stateful như PostgreSQL, MySQL Galera, MongoDB, Redis Cluster, Kafka) lại có những đòi hỏi khắt khe mà Deployment không thể đáp ứng. **StatefulSet** ra đời để giải quyết bài toán đặc thù này.

---

## 1. Sự Khác Biệt Giữa Deployment Và StatefulSet

| Tiêu Chí So Sánh | Deployment (Stateless) | StatefulSet (Stateful) |
| :--- | :--- | :--- |
| **Định danh tên Pod** | Ngẫu nhiên (ví dụ: `web-6d8b-xyz12`) | Cố định, tăng dần từ số 0 (`db-0`, `db-1`, `db-2`) |
| **Thứ tự khởi tạo** | Đồng thời (khởi tạo song song tất cả Pod) | Tuần tự nghiêm ngặt (0 xong mới tới 1, 1 xong mới tới 2) |
| **Thứ tự kết thúc** | Bất kỳ | Đảo ngược tuần tự (giảm từ chỉ số lớn nhất về 0) |
| **Gắn kết ổ đĩa** | Dùng chung PVC hoặc không lưu trữ bền vững | Mỗi Pod sở hữu một PVC riêng biệt qua `volumeClaimTemplates` |
| **Dịch vụ mạng** | Service thông thường (cân bằng tải ngẫu nhiên) | **Headless Service** (`clusterIP: None`) định danh riêng từng Pod |

```
┌─────────────────────────────────────────────────────────────┐
│ HEADLESS SERVICE (clusterIP: None)                          │
│                                                             │
│   db-0.db-service.default ──► Trỏ thẳng đến IP của db-0     │
│   db-1.db-service.default ──► Trỏ thẳng đến IP của db-1     │
└─────────────────────────────────────────────────────────────┘
                               ▲
┌──────────────────────────────┴──────────────────────────────┐
│ STATEFULSET: db-cluster (replicas: 2)                       │
│                                                             │
│   ┌────────────────────┐            ┌────────────────────┐  │
│   │   Pod: db-cluster-0│            │   Pod: db-cluster-1│  │
│   └─────────┬──────────┘            └─────────┬──────────┘  │
│             │                                 │             │
│             ▼                                 ▼             │
│   ┌────────────────────┐            ┌────────────────────┐  │
│   │ PVC: data-cluster-0│            │ PVC: data-cluster-1│  │
│   │   (Ổ đĩa riêng 0)  │            │   (Ổ đĩa riêng 1)  │  │
│   └────────────────────┘            └────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Các Bước Thực Hành Hướng Dẫn

### 2.1 — Khởi tạo Headless Service làm đầu mối định danh mạng

Một Headless Service được nhận diện thông qua thuộc tính `clusterIP: None`. Kubernetes sẽ không cấp một IP ảo duy nhất, mà sẽ trả về các bản ghi DNS trực tiếp cho từng Pod:

```bash
cat << 'EOF' > /root/k8s-advanced/headless-svc.yaml
apiVersion: v1
kind: Service
metadata:
  name: db-service
  labels:
    app: database
spec:
  clusterIP: None
  selector:
    app: database
  ports:
  - port: 80
    name: web
EOF
```{{exec}}

Áp dụng cấu hình Headless Service:

```bash
kubectl apply -f /root/k8s-advanced/headless-svc.yaml
```{{exec}}

---

### 2.2 — Khởi tạo StatefulSet với mẫu cấp phát đĩa tự động (volumeClaimTemplates)

Tạo tệp khai báo StatefulSet `db-cluster` với 2 bản sao:

```bash
cat << 'EOF' > /root/k8s-advanced/statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: db-cluster
spec:
  serviceName: "db-service"
  replicas: 2
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: db-store
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: db-store
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 100Mi
EOF
```{{exec}}

Áp dụng vào cụm:

```bash
kubectl apply -f /root/k8s-advanced/statefulset.yaml
```{{exec}}

---

### 2.3 — Quan sát thứ tự khởi động và các PVC độc lập

Theo dõi danh sách Pod của StatefulSet:

```bash
kubectl get pods -l app=database -w
```{{exec}}

*(Nhấn `Ctrl + C` sau khi thấy cả 2 Pod đã ở trạng thái `Running`).*

Bạn sẽ quan sát thấy Pod `db-cluster-0` được khởi tạo và chuyển sang `Running` hoàn tất, sau đó Kubernetes mới bắt đầu khởi tạo tiếp `db-cluster-1`.

Kiểm tra danh sách các PVC được tự động tạo riêng biệt cho từng Pod:

```bash
kubectl get pvc -l app=database
```{{exec}}

Hai PVC riêng biệt gồm `db-store-db-cluster-0` và `db-store-db-cluster-1` đã được tạo tự động và liên kết cố định với từng Pod tương ứng!

---

## 3. Bài Tập Thử Thách

> [!TIP] Hãy hoàn thành các thao tác hướng dẫn ở trên trước khi thực hiện thử thách tự lập này.

Khi nhu cầu lưu trữ và truy vấn tăng cao, người quản trị cần bổ sung thêm một nút dữ liệu mới vào cụm StatefulSet.

**Yêu cầu:**
1. Mở rộng quy mô của StatefulSet `db-cluster` từ 2 bản sao lên đúng **3 bản sao** (`replicas: 3`).
2. Quan sát và xác nhận Pod thứ ba mang tên `db-cluster-2` được khởi tạo tuần tự và đạt trạng thái `Running`.
3. Kiểm tra và xác nhận hệ thống đã tự động cấp phát một PVC mới tương ứng có tên là `db-store-db-cluster-2` ở trạng thái `Bound`.

**Gợi ý:**
- Bạn có thể sử dụng câu lệnh `kubectl scale statefulset db-cluster --replicas=3` hoặc chỉnh sửa trực tiếp thông số `replicas` trong tệp YAML và thực hiện `kubectl apply`.
- Sử dụng lệnh `kubectl get pods -l app=database` và `kubectl get pvc -l app=database` để kiểm tra sự xuất hiện của Pod thứ 3 và ổ đĩa riêng tương ứng của nó.

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
