# Bước 4: Cấu Hình Giám Sát Sức Khỏe Tự Động Với Liveness & Readiness Probes

Một tiến trình container có trạng thái `Running` không đồng nghĩa với việc ứng dụng bên trong đang phục vụ người dùng bình thường. Nếu ứng dụng rơi vào tình trạng khóa chết (deadlock), hết kết nối cơ sở dữ liệu hoặc đang trong quá trình nạp dữ liệu bộ nhớ đệm (cache warmup), người dùng sẽ liên tục gặp lỗi 502/503. Kubernetes cung cấp cơ chế đầu dò sức khỏe (**Health Check Probes**) để tự động hóa hoàn toàn việc phát hiện và khắc phục sự cố này.

---

## 1. Phân Biệt Liveness Probe Và Readiness Probe

```
                      ┌────────────────────────────────────────┐
                      │            KUBELET AGENT               │
                      └───────┬────────────────────────┬───────┘
                              │ định kỳ kiểm tra       │
            ┌─────────────────┴─────┐            ┌─────┴─────────────────┐
            │     LIVENESS PROBE    │            │    READINESS PROBE    │
            │   (Ứng dụng còn sống?)│            │ (Sẵn sàng nhận khách?)│
            └───────────┬───────────┘            └───────────┬───────────┘
                        │ Thất bại                           │ Thất bại
                        ▼                                    ▼
            ┌───────────────────────┐            ┌───────────────────────┐
            │   RESTART CONTAINER   │            │   TÁCH KHỎI SERVICE   │
            │  Khởi động lại vùng   │            │ Ngừng dẫn lưu lượng   │
            │  chứa để tự phục hồi  │            │ nhưng giữ tiến trình  │
            └───────────────────────┘            └───────────────────────┘
```

1. **Liveness Probe (Đầu dò hoạt động):**
   * Xác định xem ứng dụng có còn phản hồi hay không.
   * Nếu probe báo lỗi liên tiếp vượt ngưỡng `failureThreshold`, Kubelet sẽ **tiêu diệt và khởi động lại container** ngay lập tức.
2. **Readiness Probe (Đầu dò sẵn sàng):**
   * Xác định xem ứng dụng đã sẵn sàng tiếp nhận lưu lượng truy cập mạng từ Service hay chưa.
   * Nếu probe thất bại, Kubernetes sẽ **tạm dừng định tuyến lưu lượng vào Pod** (Pod hiển thị `0/1 READY`), nhưng **tuyệt đối không restart container**. Ngay khi probe thành công trở lại, Pod sẽ tự động được gán lại vào luồng phục vụ.

---

## 2. Các Bước Thực Hành Hướng Dẫn

### 2.1 — Khai báo Deployment tích hợp đồng thời Liveness và Readiness Probes

Tạo tệp cấu hình triển khai `probe-deploy.yaml` với cơ chế kiểm tra HTTP GET định kỳ:

```bash
cat << 'EOF' > /root/k8s-workloads/probe-deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: probe-deploy
  labels:
    app: probe-deploy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: probe-deploy
  template:
    metadata:
      labels:
        app: probe-deploy
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
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
          timeoutSeconds: 2
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 5
          timeoutSeconds: 2
          failureThreshold: 2
EOF
```{{exec}}

> [!NOTE]
> * `initialDelaySeconds`: Thời gian chờ ứng dụng khởi động xong trước khi bắt đầu gửi tín hiệu dò đầu tiên.
> * `periodSeconds`: Chu kỳ tần suất thực hiện kiểm tra (ví dụ: mỗi 5 hoặc 10 giây một lần).
> * `failureThreshold`: Số lần thất bại liên tiếp trước khi hệ thống kích hoạt hành động xử lý (restart hoặc ngắt traffic).

---

### 2.2 — Triển khai và theo dõi trạng thái sẵn sàng

Khởi chạy Deployment vào cụm:

```bash
kubectl apply -f /root/k8s-workloads/probe-deploy.yaml
```{{exec}}

Theo dõi quá trình chuyển trạng thái từ `0/1` sang `1/1 READY`:

```bash
kubectl rollout status deployment probe-deploy
```{{exec}}

Kiểm tra danh sách Pods:

```bash
kubectl get pods -l app=probe-deploy -o wide
```{{exec}}

---

### 2.3 — Kiểm tra cấu hình chi tiết và nhật ký sự kiện của Probes

Lấy tên của 1 Pod trong Deployment và truy vấn chi tiết:

```bash
PROBE_POD=$(kubectl get pods -l app=probe-deploy -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod $PROBE_POD | grep -A 10 "Liveness:"
```{{exec}}

Quan sát phần **Events** ở cuối cùng:

```bash
kubectl describe pod $PROBE_POD | tail -n 12
```{{exec}}

Bạn sẽ thấy Kubelet không ghi nhận bất kỳ cảnh báo `Unhealthy` nào vì web server Nginx trả về mã trạng thái `200 OK` cho đường dẫn gốc `/`.

---

## 3. Bài Tập Thử Thách: Dọn Dẹp Môi Trường & Xác Nhận Trạng Thái Hoạt Động

> [!TIP] Hãy hoàn thành các thao tác hướng dẫn ở trên trước khi thực hiện thử thách tự lập này.

Sau khi đã hoàn thành các bước thử nghiệm, hãy đảm bảo hệ thống Kubernetes của bạn ở trạng thái tối ưu và sẵn sàng bàn giao.

**Yêu cầu:**
1. Đảm bảo Deployment `probe-deploy` đang hoạt động ổn định trong namespace mặc định với đầy đủ cấu hình **Liveness Probe** và **Readiness Probe** trên cổng 80 đường dẫn `/`.
2. Toàn bộ các bản sao của Deployment `probe-deploy` phải đạt trạng thái sẵn sàng `READY 1/1` và `Running`.
3. Xóa bỏ Pod thử nghiệm ban đầu `standalone-worker` (ở Bước 1) để giải phóng tài nguyên CPU/RAM cho cụm.

**Gợi ý:**
- Dùng lệnh `kubectl get deployment probe-deploy` để xác nhận số bản sao sẵn sàng đạt chỉ số mong muốn.
- Dùng lệnh `kubectl delete pod standalone-worker` để hoàn tất dọn dẹp các tài nguyên không còn sử dụng.

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và hoàn thành toàn bộ bài lab.
