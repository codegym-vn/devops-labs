# Bước 1: Khám Phá Cụm Kubernetes & Tệp Cấu Hình Kubeconfig

Trong bước đầu tiên, bạn sẽ làm quen với công cụ **`kubectl`**, kiểm tra các dịch vụ thành phần của cụm Kubernetes và phân tích tệp cấu hình xác thực quản trị **`~/.kube/config`**.

---

## 1. Lý Thuyết: Cơ Chế Giao Tiếp & Tệp Kubeconfig

### 1.1 — Mô Hình Giao Tiếp Trong Kubernetes
Khi bạn thực thi bất kỳ câu lệnh `kubectl` nào:
1. `kubectl` đọc tệp cấu hình tại đường dẫn `~/.kube/config` để lấy địa chỉ máy chủ API và chứng chỉ số xác thực.
2. Gửi một yêu cầu HTTPS RESTful tới tiến trình `kube-apiserver` (thường lắng nghe tại cổng `6443`).
3. `kube-apiserver` xác thực người dùng (Authentication), kiểm tra quyền hạn (Authorization qua RBAC), sau đó phản hồi kết quả về terminal của bạn.

### 1.2 — Cấu Trúc 3 Thành Phần Của Kubeconfig
Tệp `kubeconfig` được tổ chức thành 3 khối chính:
* **Clusters:** Danh sách các cụm K8s (địa chỉ IP/Domain của API Server và chứng chỉ CA).
* **Users:** Danh sách người dùng hoặc tài khoản dịch vụ cùng khóa chứng thực cá nhân (Client Certificate / Key).
* **Contexts:** Điểm kết nối ghép cặp: một User cụ thể sẽ thao tác trên một Cluster cụ thể tại một Namespace mặc định.
* **Current-Context:** Con trỏ chỉ định ngữ cảnh hiện tại đang được `kubectl` sử dụng.

---

## 2. Thực Hành

Đảm bảo bạn đang ở terminal của máy chủ.

### 1.1 — Kiểm tra điểm kết nối của cụm (`cluster-info`)

Chạy lệnh kiểm tra các dịch vụ cốt lõi của Control Plane:

```bash
kubectl cluster-info
```{{exec}}

Quan sát kết quả:
* `Kubernetes control plane is running at https://...:6443`
* `CoreDNS is running at https://.../api/v1/namespaces/kube-system/services/kube-dns:dns/proxy`

---

### 1.2 — Liệt kê chi tiết các Node trong cụm (`get nodes -o wide`)

Xem danh sách toàn bộ máy chủ trong cụm kèm các siêu dữ liệu mở rộng:

```bash
kubectl get nodes -o wide
```{{exec}}

Phân tích các cột thông tin:
* **NAME:** Tên định danh của node (`controlplane` và `node01`).
* **STATUS:** `Ready` (Node đang hoạt động khỏe mạnh, sẵn sàng nhận tải).
* **ROLES:** `control-plane` (Node quản trị) hoặc `<none>` (Worker Node thông thường).
* **VERSION:** Phiên bản Kubernetes Kubelet đang cài đặt trên Node.
* **CONTAINER-RUNTIME:** Nền tảng thực thi vùng chứa đang chạy (ví dụ `containerd://1.7.x`).

---

### 1.3 — Khám phá tệp cấu hình Kubeconfig

1. **Xem toàn bộ cấu hình xác thực hiện hành:**
   ```bash
   kubectl config view --minify
   ```{{exec}}

2. **Liệt kê danh sách các Contexts có sẵn:**
   ```bash
   kubectl config get-contexts
   ```{{exec}}

3. **Xem Context hiện tại đang được kích hoạt:**
   ```bash
   kubectl config current-context
   ```{{exec}}

---

## 3. Bài Tập Thử Thách

> [!TIP] Hãy hoàn thành các thao tác hướng dẫn ở trên trước khi thực hiện thử thách tự lập này.

**Yêu cầu:**
1. Sử dụng lệnh truy vấn ngữ cảnh hiện tại và chuyển hướng đầu ra (redirect output `>`) để lưu tên context đang hoạt động vào tệp `/tmp/current-context.txt`.
2. Kiểm tra lại tính năng gõ tắt: sử dụng alias `k` (ví dụ chạy lệnh lấy danh sách node qua phím tắt) để xác nhận tiện ích gõ tắt đã vận hành mượt mà.

**Gợi ý:**
- Vận dụng lệnh `kubectl config current-context` đã thực hành ở mục 2.3 kết hợp toán tử điều hướng `>` ghi ra tệp đích `/tmp/current-context.txt`.
- Bạn có thể đọc lại tệp bằng lệnh `cat` để kiểm tra kết quả chứa đúng tên context `kubernetes-admin@kubernetes`.

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
