# Bước 3: Điều Phối Lưu Lượng Mạng Tầng 7 Với Ingress

Mặc dù NodePort Service cho phép người dùng bên ngoài truy cập vào ứng dụng, việc sử dụng nó trong môi trường sản xuất gặp nhiều hạn chế: mỗi ứng dụng phải chiếm một cổng ngẫu nhiên trong dải `30000-32767` (người dùng không thể ghi nhớ `domain.com:30080`), không thể định tuyến dựa trên tên miền con (subdomain) hay tiền tố đường dẫn URL, và rất khó quản trị chứng chỉ SSL/TLS tập trung. **Ingress** trong Kubernetes giải quyết toàn bộ các bài toán này ở tầng ứng dụng (Tầng 7 HTTP/HTTPS).

---

## 1. Cơ Chế Định Tuyến Của Ingress

```
                               ┌───────────────────────────┐
                               │   KHÁCH HÀNG TRÊN MẠNG    │
                               └─────────────┬─────────────┘
                                             │ HTTP (Cổng 80)
                                             ▼
                               ┌───────────────────────────┐
                               │     INGRESS CONTROLLER    │
                               │   (Reverse Proxy Nginx)   │
                               └───────┬───────────┬───────┘
                     Đường dẫn /apple  │           │  Đường dẫn /banana
                                       ▼           ▼
                         ┌────────────────┐     ┌────────────────┐
                         │   Service:     │     │   Service:     │
                         │ apple-service  │     │ banana-service │
                         └───────┬────────┘     └───────┬────────┘
                                 ▼                      ▼
                         [ Pod Apple App ]      [ Pod Banana App ]
```

* **Ingress Resource:** Tệp khai báo luật định tuyến (ví dụ: URL nào trỏ về Service nào).
* **Ingress Controller:** Phần mềm proxy thực thi các quy tắc đó (như Nginx Ingress Controller, Traefik, HAProxy). Controller lắng nghe liên tục các thay đổi của Ingress Resource và tự động cập nhật cấu hình điều phối lưu lượng.
* **Định tuyến theo đường dẫn (Path-based Routing):** Cùng một tên miền nhưng `/apple` sẽ dẫn tới một nhóm Pod khác với `/banana`.

---

## 2. Các Bước Thực Hành Hướng Dẫn

### 2.1 — Khởi tạo hai ứng dụng mẫu đại diện cho hai dịch vụ độc lập

Tạo hai dịch vụ `apple-service` và `banana-service` chạy trên hai tập hợp Pod khác nhau:

```bash
cat << 'EOF' > /root/k8s-networking/apps-and-services.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apple-deploy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: apple
  template:
    metadata:
      labels:
        app: apple
    spec:
      containers:
      - name: apple-app
        image: hashicorp/http-echo:0.2.3
        args: ["-text=Xin chao tu DICH VU QUA TAO (Apple Service)!"]
        ports:
        - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: apple-service
spec:
  type: ClusterIP
  selector:
    app: apple
  ports:
  - port: 80
    targetPort: 5678
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: banana-deploy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: banana
  template:
    metadata:
      labels:
        app: banana
    spec:
      containers:
      - name: banana-app
        image: hashicorp/http-echo:0.2.3
        args: ["-text=Xin chao tu DICH VU QUA CHUOI (Banana Service)!"]
        ports:
        - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: banana-service
spec:
  type: ClusterIP
  selector:
    app: banana
  ports:
  - port: 80
    targetPort: 5678
EOF
```{{exec}}

Kích hoạt các ứng dụng và dịch vụ vào cụm:

```bash
kubectl apply -f /root/k8s-networking/apps-and-services.yaml
```{{exec}}

Kiểm tra trạng thái triển khai:

```bash
kubectl get deployment,svc -l 'app in (apple, banana)'
```{{exec}}

---

### 2.2 — Khởi tạo Ingress định tuyến dựa trên đường dẫn URL

Tạo tệp cấu hình Ingress quy định đường dẫn truy cập cho từng ứng dụng:

```bash
cat << 'EOF' > /root/k8s-networking/path-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: path-based-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - http:
      paths:
      - path: /apple
        pathType: Prefix
        backend:
          service:
            name: apple-service
            port:
              number: 80
      - path: /banana
        pathType: Prefix
        backend:
          service:
            name: banana-service
            port:
              number: 80
EOF
```{{exec}}

> [!NOTE]
> * `pathType: Prefix`: Khớp mọi đường dẫn bắt đầu bằng chuỗi chỉ định (ví dụ: `/apple`, `/apple/details`).
> * `rewrite-target: /`: Hướng dẫn Ingress chuyển tiếp đường dẫn gốc vào bên trong container sau khi bóc tách tiền tố URL bên ngoài.

Áp dụng cấu hình Ingress:

```bash
kubectl apply -f /root/k8s-networking/path-ingress.yaml
```{{exec}}

---

### 2.3 — Kiểm tra cấu hình và các điểm cuối của Ingress

Xem thông tin Ingress vừa tạo:

```bash
kubectl get ingress path-based-ingress
```{{exec}}

Xem chi tiết bảng định tuyến các quy tắc:

```bash
kubectl describe ingress path-based-ingress
```{{exec}}

Trong phần **Rules**, bạn sẽ thấy rõ cấu trúc hai nhánh đường dẫn:
* `/apple` trỏ về `apple-service:80`
* `/banana` trỏ về `banana-service:80`

---

## 3. Bài Tập Thử Thách

> [!TIP] Hãy hoàn thành các thao tác hướng dẫn ở trên trước khi thực hiện thử thách tự lập này.

Bộ phận kinh doanh muốn mở thêm một cổng vào cho gian hàng trực tuyến thông qua đường dẫn `/store`.

**Yêu cầu:**
1. Khởi tạo một đối tượng Ingress có tên là `app-ingress` trong namespace `default`.
2. Định cấu hình một quy tắc định tuyến cho đường dẫn `/store` với kiểu đường dẫn `Prefix`.
3. Chuyển tiếp toàn bộ lưu lượng của đường dẫn `/store` đến dịch vụ `order-service` (đã được tạo ở Bước 2) trên cổng số `80`.
4. Kiểm tra và xác nhận Ingress `app-ingress` đã tồn tại trên cụm và hiển thị chính xác bảng quy tắc trỏ về `order-service:80`.

**Gợi ý:**
- Khai báo chuẩn tài nguyên `apiVersion: networking.k8s.io/v1` với `kind: Ingress`.
- Trong mục `paths`, chỉ định `path: /store`, `pathType: Prefix`, và thiết lập `backend.service.name: order-service` cùng `backend.service.port.number: 80`.
- Sử dụng lệnh `kubectl describe ingress app-ingress` để xác nhận đường dẫn đã gắn kết thành công với dịch vụ đích.

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
