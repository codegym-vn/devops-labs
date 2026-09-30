# Lab 19: Thực Hành Tương Tác Với Cụm K8s & Kiểm Tra Trạng Thái Node Qua kubectl

Chào mừng bạn đến với học phần **Container Orchestration với Kubernetes**. Trong bài lab mở đầu này, bạn sẽ trực tiếp điều khiển một cụm Kubernetes thực tế gồm 2 Nodes bằng công cụ dòng lệnh **kubectl**, làm chủ cách kiểm tra sức khỏe của hạ tầng và thực thi các thao tác vận hành nút mạng chuẩn Production.

---

## 1. Kiến Trúc Cụm Kubernetes: Control Plane & Worker Nodes

Một cụm Kubernetes phân tách rõ ràng thành hai vai trò cốt lõi:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  KIẾN TRÚC TỔNG QUAN CỤM KUBERNETES 2 NODES                                │
│                                                                             │
│   [ CONTROL PLANE (controlplane) ]            [ WORKER NODE (node01) ]      │
│   ┌───────────────────────────────┐           ┌───────────────────────────┐ │
│   │ • kube-apiserver (Cổng REST)  │           │ • kubelet (Đặc vụ node)   │ │
│   │ • etcd (Bộ não lưu dữ liệu)   │ ───────►  │ • kube-proxy (Mạng Pod)   │ │
│   │ • kube-scheduler (Lập lịch)   │           │ • containerd (Runtime)    │ │
│   │ • kube-controller-manager     │           │                           │ │
│   │                               │           │ ┌───────┐   ┌───────┐     │ │
│   │ Taint: NoSchedule (Mặc định)  │           │ │ Pod A │   │ Pod B │     │ │
│   └───────────────────────────────┘           │ └───────┘   └───────┘     │ │
│                   ▲                           └───────────────────────────┘ │
│                   │ Lệnh gọi REST API                                       │
│          [ kubectl CLI Client ]                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

* **Control Plane (`controlplane`):** Bộ chỉ huy trung tâm, tiếp nhận các yêu cầu khai báo qua `kube-apiserver` và điều phối việc đặt Pod vào các máy chủ phù hợp. Mặc định node này có Taint chặn không cho ứng dụng thông thường chạy đè lên hệ thống.
* **Worker Node (`node01`):** Nơi thực sự chạy các vùng chứa ứng dụng (Containers/Pods). Kubelet nhận chỉ thị từ Control Plane để duy trì vòng đời các container.
* **`kubectl`:** Công cụ dòng lệnh giao tiếp với cụm, xác thực danh tính dựa vào tệp cấu hình `~/.kube/config`.

---

## 2. Mục Tiêu Học Tập

Sau khi hoàn thành bài thực hành này, học viên có khả năng:
* **Khám phá** kiến trúc tổng quan của cụm Kubernetes giữa Control Plane và Worker Nodes cùng cấu trúc tệp xác thực quản trị `~/.kube/config`.
* **Phân tích và đánh giá** trạng thái vận hành của Node thông qua các điều kiện sức khỏe và tỷ lệ tài nguyên khả dụng.
* **Quản trị siêu dữ liệu** của Node bằng Labels và Annotations phục vụ việc phân loại và thiết lập cơ chế định tuyến Pod có điều kiện.
* **Thực thi** quy trình bảo trì máy chủ an toàn trong môi trường Production thông qua các lệnh điều phối nút mạng.
