# Bước 4: Giả Lập Sự Cố Phiên Bản Mới & Kích Hoạt Cơ Chế Rollback Khẩn Cấp

Sức mạnh lớn nhất của chiến lược Canary là **Khả năng cô lập rủi ro (Blast Radius Containment)**. Khi một phiên bản phần mềm chứa lỗi nghiêm trọng được triển khai, sự cố sẽ lập tức bị chặn đứng mà không ảnh hưởng tới toàn bộ hệ thống.

Trong bước này, bạn sẽ đóng vai trò người vận hành khi phiên bản mới (v3.0) bị lỗi, chạy script giám sát phát hiện sự cố và thực hiện Rollback tức thì.

---

## 1. Kịch Bản Sự Cố

Nhóm phát triển chuẩn bị phát hành phiên bản v3.0, nhưng mã nguồn vô tình chứa lỗi khởi động làm tiến trình ứng dụng lập tức bị sập (Crash).

Nếu áp dụng phương thức cập nhật trực tiếp (In-place hoặc Big Bang), toàn bộ ứng dụng sẽ ngừng hoạt động. Nhưng với Canary:
* Phiên bản ổn định `web-stable` (4 Pods) vẫn đang tiếp tục phục vụ người dùng.
* Chỉ có Pod Canary v3 gặp lỗi.
* Script kiểm thử phát hiện tỷ lệ lỗi tăng vọt và từ chối cấp phép.
* Kỹ sư vận hành kích hoạt Rollback chỉ bằng một câu lệnh xóa Deployment Canary.

---

## 2. Các Bước Thực Hiện

### 2.1 — Triển khai phiên bản Canary v3 bị lỗi

Tạo tệp manifest `deployment-canary-faulty.yaml` mô phỏng phiên bản chứa lỗi sập tiến trình (CrashLoopBackOff):

```bash
cd /root/canary-lab
cat << 'EOF' > deployment-canary-faulty.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-canary-faulty
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-app
      track: canary
  template:
    metadata:
      labels:
        app: web-app
        track: canary
    spec:
      containers:
        - name: app
          image: busybox:1.36
          command: ["sh", "-c", "echo 'Application crashing...'; exit 1"]
          ports:
            - containerPort: 80
EOF
```{{exec}}

Triển khai phiên bản lỗi lên cụm:

```bash
kubectl apply -f deployment-canary-faulty.yaml
```{{exec}}

Kiểm tra danh sách Pod sau vài giây:

```bash
kubectl get pods -l app=web-app -L track
```{{exec}}

Bạn sẽ thấy Pod của `web-canary-faulty` liên tục bị khởi động lại và rơi vào trạng thái `CrashLoopBackOff`. Trong khi đó, toàn bộ 4 Pod của `web-stable` vẫn duy trì trạng thái `Running` bình thường.

---

### 2.2 — Chạy script giám sát và phát hiện sự cố

Thực thi lại script kiểm tra tự động mà bạn đã viết ở Bước 3:

```bash
./verify-canary.sh
```{{exec}}

Vì Pod của Canary bị lỗi nên các kết nối hoặc kiểm tra sức khỏe sẽ ghi nhận lỗi hoặc Kubernetes tự động loại trừ Pod chưa Ready ra khỏi Endpoints. Nhờ cơ chế này, hệ thống bảo vệ người dùng không gửi yêu cầu vào Pod bị hỏng:

```bash
kubectl get endpoints web-service
```{{exec}}

Chỉ có 4 IP của `web-stable` nằm trong Endpoints. Pod lỗi của Canary bị loại bỏ hoàn toàn.

---

### 2.3 — Thực hiện Rollback khẩn cấp

Để loại bỏ hoàn toàn rủi ro và thu hồi tài nguyên của phiên bản lỗi, kỹ sư vận hành thực hiện thao tác Rollback đơn giản nhất: Xóa bỏ Deployment Canary bị lỗi:

```bash
kubectl delete -f deployment-canary-faulty.yaml
```{{exec}}

Kiểm tra lại danh sách Pod để xác nhận hệ thống đã hoàn toàn sạch sẽ:

```bash
kubectl get pods -l app=web-app
```{{exec}}

Toàn bộ cụm tiếp tục vận hành với 4 Pod của phiên bản ổn định mà không phát sinh bất kỳ giây gián đoạn nào (Zero Downtime).

Nhấn **Check** để hoàn thành Bước 4!
