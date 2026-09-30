# Bước 3: Tự Động Mở Rộng Quy Mô Theo Tải Với Horizontal Pod Autoscaler (HPA)

Trong vận hành thực tế, việc mở rộng quy mô bằng lệnh thủ công (`kubectl scale`) là không khả thi khi lưu lượng truy cập biến thiên liên tục suốt ngày đêm. Nếu không có cơ chế tự động hóa, hệ thống sẽ rơi vào tình trạng quá tải vào giờ cao điểm hoặc lãng phí chi phí hạ tầng nghiêm trọng vào ban đêm. **Horizontal Pod Autoscaler (HPA)** chính là bộ não tự động điều chỉnh số lượng bản sao Pod dựa trên mức độ tiêu thụ CPU và RAM thời gian thực.

---

## 1. Cơ Chế Hoạt Động Của HPA

```
┌─────────────────────────────────────────────────────────────┐
│                    KUBE-CONTROLLER-MANAGER                  │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │         HORIZONTAL POD AUTOSCALER (HPA)             │   │
│   │   - Min: 1 bản sao  |  Max: 5 bản sao               │   │
│   │   - Ngưỡng mục tiêu : CPU trung bình 50%            │   │
│   └───────────────▲─────────────────────┬───────────────┘   │
│                   │                     │                   │
│      Định kỳ 15s  │ truy vấn chỉ số     │ Điều chỉnh        │
│                   │                     │ số lượng Replicas │
│   ┌───────────────┴───────────────┐     ▼                   │
│   │        METRICS-SERVER         │  [ DEPLOYMENT ]         │
│   │ (Thu thập CPU/RAM từ Kubelet) │  Pod 1 ──► Pod 2 ──► ...│
│   └───────────────────────────────┘                         │
└─────────────────────────────────────────────────────────────┘
```

* **Điều kiện tiên quyết số 1:** Pod **bắt buộc phải có khai báo `resources.requests.cpu`**. Nếu không có `requests`, HPA không có hệ quy chiếu để tính toán tỷ lệ phần trăm tiêu thụ và sẽ hiển thị trạng thái `<unknown>`.
* **Công thức tính toán bản sao:**
  `Số lượng bản sao mới = Làm tròn lên ( Số bản sao hiện tại * ( Mức tiêu thụ thực tế / Ngưỡng mục tiêu ) )`

---

## 2. Các Bước Thực Hành Hướng Dẫn

### 2.1 — Kiểm tra tình trạng hoạt động của Metrics-Server

Kiểm tra xem hệ thống đã thu thập được dữ liệu tài nguyên hay chưa:

```bash
kubectl top nodes
```{{exec}}

Nếu câu lệnh trả về bảng tỷ lệ phần trăm CPU và RAM của các Node, nghĩa là `metrics-server` đã hoạt động hoàn hảo.

---

### 2.2 — Triển khai ứng dụng mẫu có khai báo tài nguyên tính toán

Tạo Deployment `php-apache` có định nghĩa `resources.requests`:

```bash
cat << 'EOF' > /root/k8s-advanced/php-apache.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-apache
spec:
  replicas: 1
  selector:
    matchLabels:
      run: php-apache
  template:
    metadata:
      labels:
        run: php-apache
    spec:
      containers:
      - name: php-apache
        image: registry.k8s.io/hpa-example
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: 500m
          requests:
            cpu: 200m
---
apiVersion: v1
kind: Service
metadata:
  name: php-apache
  labels:
    run: php-apache
spec:
  ports:
  - port: 80
  selector:
    run: php-apache
EOF
```{{exec}}

Áp dụng cấu hình:

```bash
kubectl apply -f /root/k8s-advanced/php-apache.yaml
```{{exec}}

---

### 2.3 — Cấu hình Horizontal Pod Autoscaler (HPA)

Khởi tạo một bộ HPA với ngưỡng mục tiêu CPU là `50%`, dao động từ 1 đến 5 bản sao:

```bash
kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=5
```{{exec}}

Kiểm tra trạng thái HPA:

```bash
kubectl get hpa php-apache
```{{exec}}

Quan sát cột **TARGETS**: sau khoảng 15-30 giây để Metrics-server thu thập số liệu, chỉ số sẽ hiển thị dạng `0%/50%` (tiêu thụ hiện tại là 0% so với ngưỡng 50%).

---

### 2.4 — Mô phỏng quá trình tăng tải và quan sát tự động mở rộng

Khởi chạy một tiến trình gửi liên tục hàng nghìn yêu cầu HTTP để kích hoạt tăng tải CPU:

```bash
kubectl run -i --tty load-generator --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://php-apache; done"
```{{exec}}

*(Mở một terminal mới hoặc để tiến trình chạy khoảng 1-2 phút, sau đó nhấn `Ctrl + C` để dừng tải).*

Kiểm tra sự thay đổi của HPA và số lượng bản sao:

```bash
kubectl get hpa php-apache
kubectl get deployment php-apache
```{{exec}}

Bạn sẽ thấy cột **REPLICAS** tự động nhảy từ 1 lên 2, 3, 4 hoặc 5 tùy thuộc vào độ tăng vọt của tải CPU!

---

## 3. Bài Tập Thử Thách

> [!TIP] Hãy hoàn thành các thao tác hướng dẫn ở trên trước khi thực hiện thử thách tự lập này.

Bộ phận giám sát hạ tầng yêu cầu cấu hình một chính sách co giãn tự động mới theo tiêu chuẩn chịu tải cao cho ứng dụng `php-apache`.

**Yêu cầu:**
1. Khởi tạo một đối tượng HorizontalPodAutoscaler có tên là `web-hpa` trong namespace mặc định (`default`).
2. Đối tượng co giãn mục tiêu: Deployment `php-apache`.
3. Thiết lập các thông số ngưỡng:
   - Số lượng bản sao tối thiểu (`minReplicas`): `2`
   - Số lượng bản sao tối đa (`maxReplicas`): `6`
   - Ngưỡng sử dụng CPU trung bình mục tiêu: `60%`
4. Kiểm tra và xác nhận HPA `web-hpa` đã được khởi tạo thành công với đúng các ngưỡng chỉ định.

**Gợi ý:**
- Bạn có thể sử dụng câu lệnh `kubectl autoscale deployment php-apache --name=web-hpa --cpu-percent=60 --min=2 --max=6` hoặc khai báo bằng tệp YAML chuẩn `apiVersion: autoscaling/v2`.
- Sử dụng lệnh `kubectl describe hpa web-hpa` để rà soát các thông số min/max và ngưỡng phần trăm CPU.

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
