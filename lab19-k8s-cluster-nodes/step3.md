# Bước 3: Quản Trị Siêu Dữ Liệu Node & Lập Lịch Pod Có Điều Kiện

Trong bước này, bạn sẽ thực hành gắn nhãn (**Labels**) phân loại máy chủ, lọc node theo điều kiện và cấu hình cơ chế định tuyến Pod có điều kiện (**nodeSelector**) để chỉ định ứng dụng chạy trên đúng Worker Node mong muốn.

---

## 1. Lý Thuyết: Siêu Dữ Liệu Node & Cơ Chế Định Tuyến Pod

### 1.1 — Labels vs Annotations Trong Kubernetes
* **Labels (Nhãn định danh):** Là các cặp `key=value` dùng để nhận diện, nhóm và chọn lọc tài nguyên. Kube-scheduler sử dụng Labels của Node để đưa ra quyết định đặt Pod vào đâu.
  * Ví dụ: `hardware=ssd`, `region=us-east-1`, `tier=backend`.
* **Annotations (Ghi chú phi định danh):** Dùng để lưu trữ các thông tin hỗ trợ cho công cụ bên ngoài (phiên bản Git commit, email người phụ trách, thời gian tạo), không được dùng làm điều kiện lọc tài nguyên.

### 1.2 — Cơ Chế Điều Phối `nodeSelector`
Trong tệp khai báo cấu hình Pod (YAML), khối `spec.nodeSelector` cho phép kỹ sư ràng buộc:
* Pod này **CHỈ ĐƯỢC PHÉP** chạy trên những Node sở hữu chính xác cặp nhãn được khai báo.
* Nếu trong toàn bộ cụm không có Node nào thỏa mãn, Kube-scheduler sẽ giữ Pod ở trạng thái `Pending` cho đến khi xuất hiện máy chủ phù hợp.

---

## 2. Thực Hành

Đảm bảo bạn đang ở thư mục `/root/k8s-lab`.

### 2.1 — Khám phá các nhãn mặc định trên Node

Kiểm tra toàn bộ nhãn hệ thống do Kubeadm tự động gán cho `node01`:

```bash
kubectl get node node01 --show-labels
```{{exec}}

Bạn sẽ thấy các nhãn tiêu chuẩn như kiến trúc CPU (`kubernetes.io/arch=amd64`), hệ điều hành (`kubernetes.io/os=linux`), và tên máy (`kubernetes.io/hostname=node01`).

---

### 2.2 — Gắn nhãn phân loại phần cứng cho Worker Node

Gắn thêm 2 nhãn tùy chỉnh vào `node01` để đánh dấu đây là node có ổ cứng SSD và thuộc môi trường Production:

```bash
kubectl label node node01 hardware=ssd environment=production
```{{exec}}

Xác nhận nhãn đã được nạp thành công bằng cách sử dụng cờ lọc nhãn (`-l` hoặc `--selector`):

```bash
kubectl get nodes -l hardware=ssd
```{{exec}}

*Chỉ có duy nhất `node01` thỏa mãn điều kiện và hiển thị trên màn hình!*

---

### 2.3 — Triển khai Pod có ràng buộc `nodeSelector`

Tạo tệp cấu hình Pod mang tên `ssd-pod.yaml` yêu cầu phải chạy trên node có nhãn `hardware=ssd`:

```bash
cat << 'EOF' > /root/k8s-lab/ssd-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: ssd-app
  labels:
    app: ssd-app
spec:
  nodeSelector:
    hardware: ssd
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
EOF
```{{exec}}

Khởi chạy Pod vào cụm:

```bash
kubectl apply -f /root/k8s-lab/ssd-pod.yaml
```{{exec}}

Kiểm tra vị trí thực thi thực tế của Pod:

```bash
kubectl get pod ssd-app -o wide
```{{exec}}

Quan sát cột **NODE**: Pod `ssd-app` đã được Kube-scheduler tự động điều phối chuẩn xác 100% về máy chủ **`node01`**!

---

## 3. Bài Tập Thử Thách: Gỡ Bỏ Nhãn Khỏi Máy Chủ

> [!TIP] Hãy hoàn thành các thao tác hướng dẫn ở trên trước khi thực hiện thử thách tự lập này.

**Yêu cầu:**
1. Thực thi gỡ bỏ nhãn `environment` khỏi máy chủ `node01` (đảm bảo sau thao tác, `node01` không còn mang nhãn này).
2. Dùng bộ lọc nhãn (`-l`) kiểm tra lại để xác nhận không còn máy chủ nào thỏa mãn điều kiện `environment=production`.
3. Kiểm tra và đảm bảo nhãn `hardware=ssd` vẫn được duy trì nguyên vẹn trên `node01`.

**Gợi ý:**
- Trong Kubernetes, để xóa một Label khỏi tài nguyên bất kỳ, bạn dùng lệnh gán nhãn nhưng thêm ký hiệu dấu trừ `-` ngay sau tên Key: `kubectl label node <tên-node> <tên-key>-`.
- Sau khi gỡ, sử dụng cờ `-l` để truy vấn kiểm tra kết quả xem nhãn cũ đã biến mất và nhãn `hardware=ssd` vẫn tồn tại hay chưa.

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
