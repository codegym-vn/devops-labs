# Bước 4: Đóng Gói Và Quản Trị Ứng Dụng Với Helm Chart

Khi một dự án microservice phát triển lớn mạnh, một ứng dụng thường bao gồm hàng chục tệp YAML: Deployment, Service, Ingress, ConfigMap, Secret, HPA, ServiceAccount. Nếu phải chỉnh sửa thủ công từng tệp để triển khai cho từng môi trường (Development, Staging, Production), các lỗi gõ nhầm và sai lệch phiên bản (Configuration Drift) là không thể tránh khỏi. **Helm** — công cụ quản lý gói tiêu chuẩn công nghiệp của CNCF — mang đến giải pháp đóng gói mẫu hóa (templating) và quản trị vòng đời ứng dụng chuyên nghiệp.

---

## 1. Cấu Trúc Cốt Lõi Của Một Helm Chart

```
my-webapp/
├── Chart.yaml          # Siêu dữ liệu của Chart (tên, phiên bản chart, phiên bản app)
├── values.yaml         # Các giá trị biến số mặc định (Replicas, Image, Port...)
├── charts/             # Thư mục chứa các Chart con phụ thuộc (Dependencies)
└── templates/          # Các tệp khuôn mẫu YAML (Go Template engine)
    ├── deployment.yaml # Khuôn mẫu Deployment sử dụng biến {{ .Values.xxx }}
    ├── service.yaml    # Khuôn mẫu Service
    ├── hpa.yaml        # Khuôn mẫu HPA
    └── _helpers.tpl    # Các hàm tiện ích tái sử dụng trong template
```

* **Chart:** Gói mã nguồn đóng gói toàn bộ định nghĩa ứng dụng Kubernetes.
* **Values:** Tệp cung cấp tham số đầu vào. Bằng cách thay thế `values.yaml` khác nhau, bạn có thể triển khai cùng một bộ Chart cho Dev, Staging và Production mà không cần sửa bất kỳ dòng mã YAML nào trong `templates/`.
* **Release:** Một thực thể cài đặt cụ thể của Chart đang chạy trên cụm. Mỗi lần nâng cấp cấu hình, Helm sẽ lưu lại lịch sử phiên bản (`REVISION`) cho phép bạn dễ dàng quay lui (Rollback) chỉ với một câu lệnh.

---

## 2. Các Bước Thực Hành Hướng Dẫn

### 2.1 — Khởi tạo cấu trúc Helm Chart tiêu chuẩn

Sử dụng lệnh `helm create` để sinh tự động bộ khung ứng dụng web chuẩn:

```bash
cd /root/k8s-advanced
helm create my-webapp
```{{exec}}

Kiểm tra cấu trúc thư mục vừa sinh:

```bash
ls -la my-webapp
ls -la my-webapp/templates
```{{exec}}

Xem tệp siêu dữ liệu `Chart.yaml`:

```bash
cat my-webapp/Chart.yaml
```{{exec}}

---

### 2.2 — Tùy biến và kiểm tra kết quả sinh mẫu (Dry-run Rendering)

Xem qua các biến số quan trọng trong `values.yaml`:

```bash
head -n 25 my-webapp/values.yaml
```{{exec}}

Trước khi triển khai thực tế vào cụm, bạn có thể dùng lệnh `helm template` để kiểm tra kết quả biên dịch xem các biến số được ghép vào tệp YAML như thế nào:

```bash
helm template test-render ./my-webapp | grep -A 10 "kind: Deployment"
```{{exec}}

---

### 2.3 — Triển khai ứng dụng vào cụm với `helm install`

Cài đặt Chart với tên bản phát hành là `web-release`:

```bash
helm install web-release ./my-webapp
```{{exec}}

Kiểm tra danh sách các bản phát hành Helm đang hoạt động:

```bash
helm list
```{{exec}}

Kiểm tra các tài nguyên Kubernetes thực tế được Helm tạo ra:

```bash
kubectl get deployment,svc,pod -l 'app.kubernetes.io/instance=web-release'
```{{exec}}

Toàn bộ hệ thống Pods và Service đã được khởi tạo đồng loạt chỉ sau một câu lệnh duy nhất!

---

## 3. Bài Tập Thử Thách

> [!TIP] Hãy hoàn thành các thao tác hướng dẫn ở trên trước khi thực hiện thử thách tự lập này.

Ban giám đốc yêu cầu tăng cường số lượng bản sao cho ứng dụng `web-release` lên 3 bản sao để chuẩn bị cho chiến dịch marketing.

**Yêu cầu:**
1. Thực hiện nâng cấp bản phát hành `web-release` đang chạy, tăng số lượng bản sao lên đúng **3 bản sao** (`replicaCount: 3`).
2. Sử dụng cơ chế ghi đè giá trị của Helm (thông qua cờ `--set replicaCount=3` hoặc cập nhật trong tệp `values.yaml` rồi thực thi lệnh nâng cấp).
3. Xác nhận rằng bản phát hành `web-release` đã được cập nhật lên số hiệu phiên bản sửa đổi thứ hai (`REVISION: 2`).
4. Kiểm tra danh sách Pods để xác nhận có đúng 3 bản sao đang chạy ổn định.

**Gợi ý:**
- Vận dụng câu lệnh nâng cấp bản phát hành của Helm kết hợp cờ thiết lập ghi đè giá trị (`--set`) chỉ định tham số số lượng bản sao mong muốn (`replicaCount=3`).
- Sử dụng lệnh `helm list` hoặc `helm history` để kiểm tra thông số phiên bản sửa đổi (`REVISION`) đạt con số 2.
- Kiểm tra danh sách Pod với `kubectl get pods -l app.kubernetes.io/instance=web-release`.

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và hoàn thành toàn bộ bài lab.
