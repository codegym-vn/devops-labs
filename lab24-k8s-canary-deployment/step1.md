# Bước 1: Khởi Tạo Service Định Tuyến & Triển Khai Phiên Bản Ổn Định (Stable v1)

Trong bước đầu tiên, bạn sẽ thiết lập lớp mạng điều phối dịch vụ và triển khai phiên bản phần mềm đầu tiên (phiên bản 1.0) chạy ổn định trên cụm với 3 Pod bản sao.

---

## 1. Cơ Chế Nhãn (Labels) Và Bộ Chọn (Selectors)

Một Kubernetes Service không gắn trực tiếp vào một Deployment cụ thể, mà tìm kiếm các Pod đích thông qua trường `spec.selector`:

* **Service Selector:** `app: web-app`
* **Stable Pod Labels:** `app: web-app` VÀ `track: stable`
* **Canary Pod Labels:** `app: web-app` VÀ `track: canary`

Vì cả hai nhóm Pod đều sở hữu nhãn chung là `app: web-app`, Service sẽ tự động gom tất cả các Pod này vào danh sách IP đích (Endpoints) và thực hiện phân phối đều lưu lượng theo cơ chế Round-Robin.

---

## 2. Các Bước Thực Hiện

### 2.1 — Khởi tạo Kubernetes Service

Di chuyển vào thư mục làm việc và tạo tệp manifest `service.yaml`:

```bash
cd /root/canary-lab
cat << 'EOF' > service.yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: ClusterIP
  selector:
    app: web-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
EOF
```{{exec}}

Áp dụng tệp manifest lên cụm:

```bash
kubectl apply -f service.yaml
```{{exec}}

Kiểm tra Service vừa tạo:

```bash
kubectl get svc web-service
```{{exec}}

---

### 2.2 — Triển khai Deployment Stable v1

Tạo tệp manifest `deployment-stable.yaml` khai báo 3 bản sao Pod với nhãn `app: web-app` và `track: stable`:

```bash
cat << 'EOF' > deployment-stable.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-stable
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
      track: stable
  template:
    metadata:
      labels:
        app: web-app
        track: stable
    spec:
      containers:
        - name: app
          image: nginxdemos/hello:plain-text
          ports:
            - containerPort: 80
          env:
            - name: APP_VERSION
              value: "v1.0-stable"
EOF
```{{exec}}

Triển khai phiên bản Stable lên cụm:

```bash
kubectl apply -f deployment-stable.yaml
```{{exec}}

Chờ toàn bộ 3 bản sao sẵn sàng:

```bash
kubectl rollout status deployment/web-stable
```{{exec}}

Kiểm tra danh sách Pod và nhãn:

```bash
kubectl get pods -l app=web-app --show-labels
```{{exec}}

Kiểm tra lại danh sách Endpoints của `web-service`:

```bash
kubectl get endpoints web-service
```{{exec}}

Bạn sẽ thấy 3 địa chỉ IP tương ứng với 3 Pod của `web-stable`.

---

### 2.3 — Kiểm tra phản hồi dịch vụ

Gửi yêu cầu thử nghiệm tới `web-service` bằng một Pod tạm:

```bash
kubectl run test-curl --image=curlimages/curl --restart=Never -it --rm -- curl -s http://web-service/
```{{exec}}

Phản hồi trả về trang thông tin server chứng minh phiên bản Stable v1 đã sẵn sàng phục vụ.

Nhấn **Check** để hoàn thành Bước 1!
