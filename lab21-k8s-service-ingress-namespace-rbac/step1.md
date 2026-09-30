# Bước 1: Phân Vùng Không Gian Ứng Dụng Với Namespace

Trong một hệ thống Kubernetes dùng chung cho nhiều nhóm dự án hoặc nhiều môi trường (Development, Staging, Production), việc đưa toàn bộ tài nguyên vào không gian mặc định (`default`) sẽ nhanh chóng dẫn đến sự hỗn loạn: trùng tên Pod, xung đột cấu hình và không thể áp dụng các chính sách bảo mật hay hạn mức tài nguyên riêng biệt. **Namespace** chính là cơ chế phân vùng ảo giúp cô lập logic các tài nguyên trong cụm.

---

## 1. Cơ Chế Hoạt Động Của Namespace

```
┌─────────────────────────────────────────────────────────────┐
│                    CỤM KUBERNETES VẬT LÝ                    │
│                                                             │
│   ┌───────────────────────┐     ┌───────────────────────┐   │
│   │ NAMESPACE: development│     │ NAMESPACE: production │   │
│   │                       │     │                       │   │
│   │   Pod: [ web-app ]    │     │   Pod: [ web-app ]    │   │
│   │   (Môi trường dev)    │     │   (Môi trường prod)   │   │
│   └───────────────────────┘     └───────────────────────┘   │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │ NAMESPACE: kube-system                              │   │
│   │ Hệ thống cốt lõi: CoreDNS, Kube-proxy, Flannel...   │   │
│   └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

* **Trùng tên hợp lệ:** Hai Pod hoặc Service hoàn toàn có thể mang cùng tên (ví dụ: `web-app`) miễn là chúng nằm ở hai Namespace khác nhau.
* **Các Namespace hệ thống mặc định:**
  * `default`: Không gian mặc định khi người dùng không chỉ định cờ `-n`.
  * `kube-system`: Nơi chứa các thành phần điều khiển của Kubernetes.
  * `kube-public` và `kube-node-lease`: Chứa dữ liệu công khai và thông tin giám sát nhịp tim (heartbeat) của các Node.

---

## 2. Các Bước Thực Hành Hướng Dẫn

### 2.1 — Khám phá các Namespace có sẵn trên cụm

Liệt kê toàn bộ các không gian tên đang tồn tại:

```bash
kubectl get namespaces
```{{exec}}

---

### 2.2 — Khởi tạo các Namespace làm việc

Tạo hai không gian làm việc độc lập cho môi trường phát triển và sản xuất:

```bash
kubectl create namespace development
kubectl create namespace production
```{{exec}}

Kiểm tra lại danh sách:

```bash
kubectl get ns
```{{exec}}

---

### 2.3 — Triển khai Pod vào từng Namespace cụ thể

**Cách 1:** Sử dụng cờ `-n` trong câu lệnh trực tiếp:

```bash
kubectl run dev-api --image=nginx:alpine -n development
```{{exec}}

**Cách 2:** Khai báo trường `namespace` trực tiếp trong tệp cấu hình YAML:

```bash
cat << 'EOF' > /root/k8s-networking/prod-api.yaml
apiVersion: v1
kind: Pod
metadata:
  name: prod-api
  namespace: production
  labels:
    tier: api
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
EOF
```{{exec}}

Khởi chạy Pod vào cụm:

```bash
kubectl apply -f /root/k8s-networking/prod-api.yaml
```{{exec}}

---

### 2.4 — Truy vấn tài nguyên theo phạm vi Namespace

Nếu chỉ chạy lệnh kiểm tra mặc định:

```bash
kubectl get pods
```{{exec}}

Hệ thống sẽ không thấy các Pod vừa tạo vì chúng nằm ngoài `default`. Để xem các Pod trong từng không gian:

```bash
kubectl get pods -n development
kubectl get pods -n production
```{{exec}}

Để hiển thị toàn bộ Pod trên tất cả các Namespace trên một màn hình duy nhất, sử dụng cờ `-A` (hoặc `--all-namespaces`):

```bash
kubectl get pods -A
```{{exec}}

---

## 3. Bài Tập Thử Thách

> [!TIP] Hãy hoàn thành các thao tác hướng dẫn ở trên trước khi thực hiện thử thách tự lập này.

Đội ngũ đảm bảo chất lượng (QA) cần một môi trường biệt lập để tiến hành thử nghiệm phiên bản mới trước khi chuyển lên Production.

**Yêu cầu:**
1. Khởi tạo một Namespace mới có tên là `staging`.
2. Triển khai một Pod độc lập có tên là `staging-web` sử dụng image `nginx:alpine` nằm trọn vẹn bên trong Namespace `staging` vừa tạo.
3. Xác nhận rằng Pod `staging-web` đã chuyển sang trạng thái `Running` trong Namespace `staging`.

**Gợi ý:**
- Vận dụng câu lệnh `kubectl create namespace` để sinh không gian tên đích.
- Kết hợp cờ `-n staging` trong lệnh `kubectl run` (hoặc khai báo `namespace: staging` trong metadata của tệp YAML) để đặt Pod vào đúng vị trí.
- Sử dụng lệnh `kubectl get pods -n staging` để kiểm tra kết quả.

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
