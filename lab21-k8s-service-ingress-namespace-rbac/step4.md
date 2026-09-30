# Bước 4: Kiểm Soát Truy Cập Dựa Trên Vai Trò Với RBAC

Trong môi trường doanh nghiệp nhiều người cùng vận hành, cấp toàn quyền quản trị (`cluster-admin`) cho tất cả mọi người là một nguy cơ bảo mật nghiêm trọng. Một câu lệnh gõ nhầm của kỹ sư mới vào nghề có thể xóa sổ toàn bộ cơ sở dữ liệu trên Production. Kubernetes áp dụng mô hình kiểm soát truy cập dựa trên vai trò (**RBAC — Role-Based Access Control**) để đảm bảo nguyên tắc đặc quyền tối thiểu (Least Privilege).

---

## 1. Ba Trụ Cột Trong Mô Hình RBAC Của Kubernetes

```
┌─────────────────────────────────────────────────────────────┐
│ 1. SUBJECT (Chủ thể thực hiện):                             │
│    - User / Group: Người dùng thực (xác thực qua OIDC, CA)  │
│    - ServiceAccount: Tài khoản dành riêng cho ứng dụng/Pod  │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               │ Gắn kết bằng:
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. ROLEBINDING (Cầu nối liên kết quyền):                    │
│    Gán Role cụ thể cho một Subject trong một Namespace      │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               │ Trao quyền từ:
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. ROLE (Tập hợp quyền hạn trong một Namespace):            │
│    - apiGroups: ["", "apps", "networking.k8s.io"]           │
│    - resources: ["pods", "deployments", "services"]         │
│    - verbs    : ["get", "list", "watch", "create", "delete"]│
└─────────────────────────────────────────────────────────────┘
```

* **Role vs ClusterRole:**
  * **Role:** Giới hạn quyền hạn nghiêm ngặt bên trong **duy nhất một Namespace** (ví dụ: chỉ được đọc Pod trong namespace `development`).
  * **ClusterRole:** Cho phép áp dụng trên **toàn bộ cụm** hoặc trên các tài nguyên phi namespace (như Node, PersistentVolume).

---

## 2. Các Bước Thực Hành Hướng Dẫn

### 2.1 — Khởi tạo ServiceAccount cho người dùng trong namespace development

Tạo tài khoản dịch vụ `dev-viewer`:

```bash
kubectl create serviceaccount dev-viewer -n development
```{{exec}}

Kiểm tra tài khoản vừa tạo:

```bash
kubectl get sa dev-viewer -n development
```{{exec}}

---

### 2.2 — Khởi tạo Role định nghĩa tập quyền hạn chỉ đọc Pods

Tạo tệp khai báo Role `pod-reader` với các hành động `get`, `list`, `watch`:

```bash
cat << 'EOF' > /root/k8s-networking/pod-reader-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: development
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
EOF
```{{exec}}

Áp dụng Role vào không gian `development`:

```bash
kubectl apply -f /root/k8s-networking/pod-reader-role.yaml
```{{exec}}

Xem thông tin quyền hạn của Role:

```bash
kubectl describe role pod-reader -n development
```{{exec}}

---

### 2.3 — Liên kết Role với ServiceAccount bằng RoleBinding

Tạo RoleBinding `dev-viewer-binding` để gắn quyền:

```bash
cat << 'EOF' > /root/k8s-networking/dev-viewer-binding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-viewer-binding
  namespace: development
subjects:
- kind: ServiceAccount
  name: dev-viewer
  namespace: development
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
EOF
```{{exec}}

Kích hoạt liên kết quyền:

```bash
kubectl apply -f /root/k8s-networking/dev-viewer-binding.yaml
```{{exec}}

---

### 2.4 — Kiểm thử ma trận phân quyền thực tế với `kubectl auth can-i`

Lệnh `kubectl auth can-i` cho phép bạn giả lập danh tính của một tài khoản để kiểm tra xem họ có quyền thực hiện hành động hay không:

1. **Kiểm tra quyền được cấp phép:** Liệt kê Pod trong namespace `development`:
   ```bash
   kubectl auth can-i list pods --as=system:serviceaccount:development:dev-viewer -n development
   ```{{exec}}
   *(Kết quả trả về: `yes` — Thao tác được phép).*

2. **Kiểm tra quyền bị từ chối:** Xóa Pod trong namespace `development`:
   ```bash
   kubectl auth can-i delete pods --as=system:serviceaccount:development:dev-viewer -n development
   ```{{exec}}
   *(Kết quả trả về: `no` — Hệ thống từ chối truy cập).*

3. **Kiểm tra tính cô lập Namespace:** Xem Pod trong namespace `production`:
   ```bash
   kubectl auth can-i list pods --as=system:serviceaccount:development:dev-viewer -n production
   ```{{exec}}
   *(Kết quả trả về: `no` — Quyền chỉ có hiệu lực bên trong namespace development).*

---

## 3. Bài Tập Thử Thách

> [!TIP] Hãy hoàn thành các thao tác hướng dẫn ở trên trước khi thực hiện thử thách tự lập này.

Trưởng nhóm dự án cần cấp quyền cho một tiến trình CI/CD tự động triển khai và thu hồi ứng dụng Deployment trong môi trường `development`.

**Yêu cầu:**
1. Khởi tạo một ServiceAccount có tên là `deploy-admin` trong namespace `development`.
2. Khởi tạo một Role có tên là `deploy-manager` trong namespace `development` với các điều kiện:
   - Thuộc nhóm API: `apps`
   - Tài nguyên cho phép: `deployments`
   - Các hành động được phép: `get`, `list`, `create`, `delete`
3. Khởi tạo một RoleBinding có tên là `manage-deploy-binding` trong namespace `development` để gán quyền của Role `deploy-manager` cho ServiceAccount `deploy-admin`.
4. Kiểm tra và xác nhận `deploy-admin` có quyền tạo Deployment nhưng không có quyền xóa Service trong namespace `development`.

**Gợi ý:**
- Tham khảo cú pháp khai báo Role và RoleBinding ở các mục 2.1, 2.2 và 2.3. Bạn có thể sử dụng cú pháp tệp YAML hoặc các lệnh tạo nhanh `kubectl create serviceaccount`, `kubectl create role` (với các cờ `--verb` và `--resource`), `kubectl create rolebinding` (với các cờ `--role` và `--serviceaccount`).
- Đảm bảo tham số `--serviceaccount` chỉ định đúng định dạng `<namespace>:<tên-serviceaccount>`.
- Sử dụng lệnh kiểm tra quyền `kubectl auth can-i` với cờ `--as` tương tự mục 2.4 để xác nhận quyền hạn trước khi nhấn hoàn thành.

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và hoàn thành toàn bộ bài lab.
