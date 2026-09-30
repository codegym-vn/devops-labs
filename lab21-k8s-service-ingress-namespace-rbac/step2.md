# Bước 2: Cân Bằng Tải & Phơi Bày Dịch Vụ Với ClusterIP Và NodePort Service

Địa chỉ IP của Pod có tính chất tạm thời (ephemeral): mỗi khi Pod bị tiêu diệt, khởi động lại hoặc mở rộng quy mô, một địa chỉ IP mới sẽ được cấp phát ngẫu nhiên. Nếu các ứng dụng gọi trực tiếp qua Pod IP, hệ thống sẽ liên tục gặp lỗi gián đoạn kết nối. **Service** trong Kubernetes giải quyết triệt để vấn đề này bằng cách đóng vai trò một đầu mối IP ảo tĩnh, tự động cân bằng tải tới tập hợp các Pods thông qua cơ chế gắn nhãn.

---

## 1. So Sánh Hai Kiểu Service Cốt Lõi

```
┌─────────────────────────────────────────────────────────────┐
│ 1. CLUSTERIP (Chỉ trong nội bộ cụm):                        │
│                                                             │
│   [ Pod Frontend ] ──► [ Service: api-svc ]                 │
│                        (Virtual IP: 10.96.x.x:80)           │
│                             │                               │
│                   ┌─────────┴─────────┐                     │
│                   ▼                   ▼                     │
│            [ Pod Backend 1 ]   [ Pod Backend 2 ]            │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ 2. NODEPORT (Phơi bày ra mạng ngoài):                       │
│                                                             │
│   [ Client Ngoài ] ──► [ Worker Node:30080 ]                │
│                             │                               │
│                             ▼                               │
│                   [ Service: web-nodeport ]                 │
│                             │                               │
│                   ┌─────────┴─────────┐                     │
│                   ▼                   ▼                     │
│            [ Pod Web 1 ]       [ Pod Web 2 ]                │
└─────────────────────────────────────────────────────────────┘
```

1. **ClusterIP (Mặc định):**
   * Được cấp phát một địa chỉ IP nội bộ trong cụm và một bản ghi DNS cố định dạng `<tên-service>.<namespace>.svc.cluster.local`.
   * Chỉ có thể truy cập được từ bên trong mạng Kubernetes. Phù hợp tuyệt đối cho cơ sở dữ liệu, hàng đợi thông điệp và các microservices nội bộ.
2. **NodePort:**
   * Mở một cổng tĩnh chuyên dụng trên **tất cả các máy chủ Node** (trong dải quy chuẩn từ `30000` đến `32767`).
   * Người dùng bên ngoài có thể gửi yêu cầu trực tiếp vào `<Địa-chỉ-IP-Node>:<NodePort>` để được điều hướng vào các Pod backend.

---

## 2. Các Bước Thực Hành Hướng Dẫn

### 2.1 — Triển khai ứng dụng Backend và Service kiểu ClusterIP

Tạo tệp cấu hình triển khai Deployment và Service nội bộ:

```bash
cat << 'EOF' > /root/k8s-networking/backend-clusterip.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deploy
  labels:
    app: backend-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend-app
  template:
    metadata:
      labels:
        app: backend-app
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: backend-svc
spec:
  type: ClusterIP
  selector:
    app: backend-app
  ports:
  - name: http
    port: 80
    targetPort: 80
EOF
```{{exec}}

Áp dụng cấu hình:

```bash
kubectl apply -f /root/k8s-networking/backend-clusterip.yaml
```{{exec}}

Kiểm tra Service và các điểm cuối (Endpoints) được tự động phát hiện:

```bash
kubectl get svc backend-svc
kubectl get endpoints backend-svc
```{{exec}}

> [!NOTE]
> Cột **ENDPOINTS** sẽ liệt kê chính xác các địa chỉ IP của 2 Pods thuộc Deployment `backend-deploy`. Khi lưu lượng gửi tới `backend-svc`, Kube-proxy sẽ tự động cân bằng tải vòng tròn (Round-Robin) giữa các địa chỉ này.

---

### 2.2 — Kiểm tra khả năng phân giải tên miền nội bộ qua Kube-DNS

Chạy một Pod tạm thời để kiểm tra truy cập vào tên Service `backend-svc`:

```bash
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- curl -s http://backend-svc
```{{exec}}

Kết quả sẽ trả về trang chào mừng chuẩn của Nginx thông qua cơ chế phân giải tên miền tự động của Kube-DNS!

---

### 2.3 — Phơi bày ứng dụng Web ra cổng máy chủ với NodePort Service

Tạo Service kiểu NodePort mở cổng tĩnh `30080`:

```bash
cat << 'EOF' > /root/k8s-networking/web-nodeport.yaml
apiVersion: v1
kind: Service
metadata:
  name: web-nodeport-svc
spec:
  type: NodePort
  selector:
    app: backend-app
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
EOF
```{{exec}}

Kích hoạt Service NodePort:

```bash
kubectl apply -f /root/k8s-networking/web-nodeport.yaml
```{{exec}}

Kiểm tra thông tin cổng được mở:

```bash
kubectl get svc web-nodeport-svc
```{{exec}}

Truy cập trực tiếp thông qua địa chỉ IP của máy chủ Worker `node01` trên cổng `30080`:

```bash
NODE01_IP=$(kubectl get node node01 -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
curl -s "http://${NODE01_IP}:30080" | grep -o "<title>.*</title>"
```{{exec}}

Trang web đã được phản hồi trực tiếp từ cổng ngoài của máy chủ Node!

---

## 3. Bài Tập Thử Thách

> [!TIP] Hãy hoàn thành các thao tác hướng dẫn ở trên trước khi thực hiện thử thách tự lập này.

Đội ngũ phát triển cần thiết lập một dịch vụ kết nối nội bộ cho khối xử lý đơn hàng (Order Processing Service) trong namespace mặc định.

**Yêu cầu:**
1. Khởi tạo một đối tượng Service kiểu `ClusterIP` có tên là `order-service` trong namespace mặc định.
2. Cấu hình bộ chọn (`selector`) để điều phối lưu lượng đến các Pod mang nhãn `app: order-app`.
3. Định nghĩa cổng dịch vụ (`port`) là `80` và cổng đích chuyển tiếp vào container (`targetPort`) là `8080`.
4. Xác nhận Service `order-service` đã xuất hiện trong danh sách dịch vụ với đúng loại và các thông số cổng yêu cầu.

**Gợi ý:**
- Bạn có thể viết một tệp YAML khai báo `kind: Service` với `type: ClusterIP` kèm theo các thông số `port`, `targetPort`, `selector` tương ứng, hoặc sử dụng lệnh sinh `kubectl create service clusterip order-service --tcp=80:8080` rồi điều chỉnh selector bằng cờ hoặc chỉnh sửa tệp YAML.
- Sử dụng lệnh `kubectl describe svc order-service` để rà soát chi tiết cấu hình cổng và nhãn bộ chọn.

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
