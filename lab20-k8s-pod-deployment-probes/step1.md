# Bước 1: Khởi Tạo Pod & Thiết Lập Hạn Mức Tài Nguyên (Requests & Limits)

Pod là viên gạch nền tảng cấu thành nên mọi tải công việc trong Kubernetes. Trong môi trường doanh nghiệp thực tế, việc đưa một Pod vào hoạt động mà không thiết lập hạn mức tài nguyên tính toán (CPU và Memory) là một rủi ro vận hành nghiêm trọng, có thể dẫn đến việc một ứng dụng bị rò rỉ bộ nhớ (memory leak) làm cạn kiệt tài nguyên của toàn bộ máy chủ vật lý.

---

## 1. Cơ Chế Quản Lý Tài Nguyên Của Kubernetes

Hệ thống điều phối Kubernetes cho phép bạn định nghĩa hai ngưỡng tài nguyên quan trọng cho mỗi container bên trong Pod:

```
┌─────────────────────────────────────────────────────────────┐
│                       NODE TÀI NGUYÊN                      │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │                    CONTAINER                        │   │
│   │                                                     │   │
│   │   [ Limits: CPU 200m / RAM 128Mi ] ── Ngưỡng trần  │   │
│   │        ▲                                            │   │
│   │        │ (Vượt quá RAM ──► OOMKilled - Exit 137)    │   │
│   │        │                                            │   │
│   │   [ Requests: CPU 100m / RAM 64Mi ] ── Cam kết sàn  │   │
│   │        ▲                                            │   │
│   └────────┼────────────────────────────────────────────┘   │
│            │ (Kube-scheduler dùng để tìm Node đặt Pod)      │
└────────────┴────────────────────────────────────────────────┘
```

1. **Requests (Mức sàn cam kết):**
   * Lượng tài nguyên tối thiểu mà Pod cần để khởi chạy ổn định.
   * Kube-scheduler sử dụng chỉ số này để tìm kiếm Node có đủ tài nguyên trống tương ứng. Nếu không có Node nào thỏa mãn, Pod sẽ ở trạng thái `Pending`.
2. **Limits (Mức trần tối đa):**
   * Giới hạn tối đa mà Linux Cgroups cho phép container tiêu thụ.
   * Nếu container tiêu thụ vượt quá giới hạn **CPU**, hệ thống sẽ tự động bóp nghẹt xung nhịp (CPU Throttling) nhưng không tắt ứng dụng.
   * Nếu container tiêu thụ vượt quá giới hạn **Memory**, nhân hệ điều hành Linux sẽ kích hoạt cơ chế OOM-Killer lập tức tiêu diệt tiến trình với mã lỗi `OOMKilled` (Exit Code 137).

---

## 2. Các Bước Thực Hành Hướng Dẫn

### 2.1 — Kỹ thuật sinh khung tệp YAML tự động với `--dry-run=client`

Thay vì tự gõ tệp YAML từ đầu dễ mắc lỗi thụt dòng (indentation), kỹ sư Kubernetes chuyên nghiệp luôn sử dụng cờ `--dry-run=client -o yaml` để sinh bản nháp:

```bash
kubectl run web-backend --image=nginx:alpine --dry-run=client -o yaml > /root/k8s-workloads/pod-base.yaml
```{{exec}}

Xem nội dung khung cấu hình vừa sinh:

```bash
cat /root/k8s-workloads/pod-base.yaml
```{{exec}}

---

### 2.2 — Cấu hình Requests và Limits vào Pod Specification

Tạo tệp cấu hình hoàn chỉnh có tích hợp khối `resources`:

```bash
cat << 'EOF' > /root/k8s-workloads/web-backend.yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-backend
  labels:
    tier: backend
spec:
  containers:
  - name: nginx-server
    image: nginx:alpine
    ports:
    - containerPort: 80
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "200m"
EOF
```{{exec}}

> [!NOTE]
> * `100m` biểu thị 100 millicores (tương đương 0.1 CPU core).
> * `64Mi` biểu thị 64 Mebibytes (tương đương 64 * 1024 * 1024 bytes).

---

### 2.3 — Khởi chạy Pod và xác minh thông số tài nguyên

Thực thi tạo Pod vào cụm:

```bash
kubectl apply -f /root/k8s-workloads/web-backend.yaml
```{{exec}}

Kiểm tra trạng thái chạy của Pod:

```bash
kubectl get pod web-backend -o wide
```{{exec}}

Truy vấn chi tiết thông tin tài nguyên đã cấp phát:

```bash
kubectl describe pod web-backend | grep -A 8 "Limits:"
```{{exec}}

Hệ thống sẽ hiển thị rõ cả hai phần `Limits` và `Requests` chính xác như ta đã khai báo trong tệp YAML.

---

## 3. Bài Tập Thử Thách

> [!TIP] Hãy hoàn thành các thao tác hướng dẫn ở trên trước khi thực hiện thử thách tự lập này.

**Yêu cầu:**
1. Khởi tạo một Pod độc lập có tên là `standalone-worker` trong namespace mặc định.
2. Pod sử dụng image `busybox` và chạy tiến trình nền giữ cho container không bị kết thúc: lệnh `sleep 3600`.
3. Định cấu hình khối tài nguyên tính toán `resources` cho container:
   - Requests: `cpu: 50m`, `memory: 64Mi`
   - Limits: `cpu: 100m`, `memory: 128Mi`
4. Khởi chạy và xác nhận Pod chuyển sang trạng thái `Running`.

**Gợi ý:**
- Bạn có thể tận dụng cờ `--dry-run=client -o yaml` kết hợp cờ `--command -- sleep 3600` của lệnh `kubectl run` để sinh bộ khung, sau đó biên tập thêm phần `resources` trước khi áp dụng vào cụm.
- Sử dụng lệnh `kubectl get pod standalone-worker` để kiểm tra trạng thái hoạt động thực tế.

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
