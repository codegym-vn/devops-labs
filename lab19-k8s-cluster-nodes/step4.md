# Bước 4: Quy Trình Bảo Trì Máy Chủ (Cordon, Drain & Uncordon)

Trong bước cuối cùng này, bạn sẽ thực hành quy trình chuẩn mực khi bảo trì máy chủ vật lý trong môi trường Production: cách ly node (**Cordon**), phân tích hành vi của bộ lập lịch khi node bị khóa, và mở quyền hoạt động trở lại (**Uncordon**).

---

## 1. Lý Thuyết: Quy Trình Bảo Trì Node Chuẩn Production

Trong thực tế vận hành hạ tầng Kubernetes, định kỳ bạn sẽ cần bảo trì phần cứng, thay thế thanh RAM, nâng cấp phiên bản hệ điều hành Linux Kernel hoặc cập nhật phần mềm Container Runtime:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  QUY TRÌNH BẢO TRÌ NÚT MẠNG 3 BƯỚC                                          │
│                                                                             │
│   [ BƯỚC 1: CORDON ]                                                        │
│   kubectl cordon node01                                                     │
│   ──► Đánh dấu 'SchedulingDisabled' (Chặn Pod mới, giữ nguyên Pod cũ)       │
│                                                                             │
│   [ BƯỚC 2: BẢO TRÌ & NÂNG CẤP ]                                            │
│   (Thao tác khởi động lại máy chủ, vá lỗi kernel an toàn)                   │
│                                                                             │
│   [ BƯỚC 3: UNCORDON ]                                                      │
│   kubectl uncordon node01                                                   │
│   ──► Mở khóa đưa node trở lại cụm để tiếp tục nhận tải bình thường         │
└─────────────────────────────────────────────────────────────────────────────┘
```

* **`kubectl cordon <node>`:** Khóa không cho phép Kube-scheduler lập lịch thêm bất kỳ Pod mới nào vào node này, nhưng **không làm gián đoạn** các Pod đang chạy sẵn.
* **`kubectl drain <node>`:** Trục xuất toàn bộ các Pod đang chạy sang node khác một cách an toàn (Graceful Eviction) để chuẩn bị tắt nguồn máy chủ.
* **`kubectl uncordon <node>`:** Xóa bỏ trạng thái `SchedulingDisabled`, cho phép máy chủ tiếp nhận Pod mới trở lại.

---

## 2. Thực Hành

Đảm bảo bạn đang ở terminal của máy chủ.

### 2.1 — Khóa máy chủ Worker (`kubectl cordon`)

Đánh dấu cách ly máy chủ `node01`:

```bash
kubectl cordon node01
```{{exec}}

Kiểm tra lại trạng thái của danh sách Node:

```bash
kubectl get nodes
```{{exec}}

Quan sát cột **STATUS** của `node01`:
`Ready,SchedulingDisabled`
*(Máy chủ vẫn khỏe mạnh nhưng đã bị đóng cửa đối với mọi Pod mới).*

---

### 2.2 — Kiểm chứng hành vi lập lịch khi Node bị khóa

Cố tình khởi tạo một Pod mới mang tên `pending-test` vào cụm:

```bash
kubectl run pending-test --image=nginx:alpine
```{{exec}}

Kiểm tra trạng thái của Pod vừa tạo:

```bash
kubectl get pod pending-test -o wide
```{{exec}}

*Hiện tượng:* Pod rơi vào trạng thái **`Pending`**!

Xem chi tiết nguyên nhân qua sự kiện hệ thống:

```bash
kubectl describe pod pending-test
```{{exec}}

Hãy nhìn vào phần **Events** ở cuối cùng:
`0/2 nodes are available: 1 node(s) had untolerated taint, 1 node(s) were unschedulable.`
* `controlplane`: Bị chặn bởi Taint quản trị mặc định.
* `node01`: Bị chặn vì đang ở trạng thái `SchedulingDisabled` do lệnh Cordon!
Bộ lập lịch K8s đã bảo vệ hệ thống chuẩn xác, không ép Pod chạy lên node đang chuẩn bị bảo trì!

---

### 2.3 — Mở khóa đưa máy chủ trở lại hoạt động (`kubectl uncordon`)

Sau khi hoàn tất bảo trì, mở khóa cho `node01`:

```bash
kubectl uncordon node01
```{{exec}}

Kiểm tra lại danh sách Node:

```bash
kubectl get nodes
```{{exec}}

*Cột STATUS của `node01` đã trở lại chữ `Ready` duy nhất!*

Kiểm tra ngay trạng thái của Pod `pending-test`:

```bash
kubectl get pod pending-test -o wide
```{{exec}}

*Kỳ diệu:* Kube-scheduler lập tức phát hiện `node01` đã sẵn sàng và điều phối `pending-test` chuyển ngay sang trạng thái **`Running`**!

---

## 3. Bài Tập Thử Thách: Dọn Dẹp Môi Trường và Đưa Cụm Về Trạng Thái Chuẩn

> [!TIP] Hãy hoàn thành các thao tác hướng dẫn ở trên trước khi thực hiện thử thách tự lập này.

**Yêu cầu:**
1. Xóa toàn bộ 2 Pod thử nghiệm đã tạo trong bài lab (`ssd-app` và `pending-test`) khỏi namespace mặc định.
2. Đảm bảo máy chủ `node01` đã được uncordon hoàn toàn (không còn cờ `SchedulingDisabled`).
3. Kiểm tra danh sách nodes để xác nhận cả `controlplane` và `node01` đều đang ở trạng thái `Ready`.

**Gợi ý:**
- Dùng lệnh `kubectl delete pod ...` để xóa đồng thời cả hai pod `ssd-app` và `pending-test`.
- Đảm bảo bạn đã chạy `kubectl uncordon node01` ở mục 2.3 để khôi phục quyền lập lịch cho `node01` trước khi nhấn kiểm tra.

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và hoàn thành toàn bộ bài lab.
