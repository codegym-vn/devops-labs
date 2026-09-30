# 🏆 Chúc Mừng! Bạn Đã Hoàn Thành Lab 19: Quản Trị Cụm K8s & Node Qua kubectl

Bạn vừa hoàn thành xuất sắc bài thực hành nhập môn **Container Orchestration với Kubernetes**, làm chủ các kỹ thuật tương tác với cụm đa máy chủ và đánh giá sức khỏe nút mạng chuẩn Production!

---

## 1. Tóm Tắt Toàn Bộ Kiến Thức Đã Đạt Được

```text
 1. Giao Tiếp Cụm & Kubeconfig:
    ~/.kube/config    ──► Nắm vững 3 khối Clusters, Users, Contexts để xác thực an toàn với API Server
    kubectl cluster-info ──► Kiểm tra endpoint Control Plane và các dịch vụ nền tảng CoreDNS
    kubectl get nodes ──► Xem tổng quan vai trò (control-plane, worker), phiên bản và runtime

 2. Đánh Giá Năng Lực & Sức Khỏe Node:
    Node Conditions   ──► Theo dõi 4 trạng thái cốt tử: Ready, MemoryPressure, DiskPressure, PIDPressure
    Capacity vs Allocatable ──► Hiểu cơ chế dự phòng tài nguyên cho hệ điều hành và kubelet
    JSONPath queries  ──► Trích xuất siêu tốc các thông số kỹ thuật phục vụ tự động hóa giám sát

 3. Điều Phối Ứng Dụng Có Điều Kiện:
    Node Labels       ──► Gắn nhãn định danh phần cứng (hardware=ssd) và lọc tài nguyên qua selector (-l)
    nodeSelector      ──► Ràng buộc Pod chỉ được phép chạy trên máy chủ đáp ứng đúng tiêu chuẩn

 4. Quy Trình Bảo Trì Máy Chủ Chuẩn CKA:
    kubectl cordon    ──► Khóa nút mạng (SchedulingDisabled), bảo toàn các Pod cũ đang hoạt động
    kubectl uncordon  ──► Mở khóa đưa máy chủ trở lại hoạt động bình thường ngay sau bảo trì
```

---

## 2. Bảng Tra Cứu Lệnh Quản Trị Node & Cụm (DevOps Cheat Sheet)

| Lệnh | Ý Nghĩa Thực Tế | Tình Huống Áp Dụng |
| :--- | :--- | :--- |
| `kubectl cluster-info` | Hiển thị địa chỉ API Server và các dịch vụ cốt lõi | Kiểm tra nhanh kết nối ban đầu tới cụm K8s |
| `kubectl get nodes -o wide` | Xem chi tiết IP nội bộ, phiên bản OS, Kernel và Container Runtime | Thu thập thông tin cấu hình phần cứng các máy chủ |
| `kubectl describe node <name>` | Xem toàn bộ sự kiện (Events), điều kiện sức khỏe và tài nguyên của Node | Điều tra lỗi khi node bị mất kết nối hoặc quá tải |
| `kubectl get node <name> -o jsonpath='{...}'` | Trích xuất trực tiếp giá trị của một trường thuộc tính cụ thể | Dùng trong Bash script giám sát hoặc kiểm tra tự động |
| `kubectl label node <name> <k>=<v>` | Gắn thêm nhãn định danh mới cho máy chủ | Phân loại node theo vị trí, loại ổ cứng, card GPU |
| `kubectl label node <name> <k>-` | Gỡ bỏ (xóa) một nhãn khỏi máy chủ (dấu trừ ở cuối) | Thu hồi phân loại node khi thay đổi cấu hình phần cứng |
| `kubectl get nodes -l <selector>` | Lọc danh sách máy chủ theo điều kiện nhãn | Tìm kiếm nhanh các node thỏa mãn tiêu chí tải |
| `kubectl cordon <name>` | Đánh dấu máy chủ không nhận thêm Pod mới (`SchedulingDisabled`) | Chuẩn bị tắt máy bảo trì phần cứng hoặc nâng cấp kernel |
| `kubectl uncordon <name>` | Mở khóa cho phép máy chủ tiếp nhận Pod trở lại | Hoàn tất bảo trì, đưa node quay lại phục vụ cụm |
| `kubectl drain <name> --ignore-daemonsets` | Trục xuất an toàn toàn bộ Pods đang chạy sang node khác | Đảm bảo tính sẵn sàng cao trước khi tắt nguồn máy chủ |

---

## 3. Câu Hỏi Phỏng Vấn DevOps & CKA Thường Gặp

1. **Sự khác nhau giữa `Capacity` và `Allocatable` trên một Kubernetes Node là gì?**
   * *Trả lời:* `Capacity` là tổng tài nguyên phần cứng vật lý mà nhân hệ điều hành nhìn thấy trên máy chủ. `Allocatable` là phần tài nguyên thực tế còn lại mà Kube-scheduler được phép phân bổ cho các Pods người dùng, sau khi đã trừ đi lượng tài nguyên dự phòng bắt buộc: `kube-reserved` (dành cho kubelet, containerd), `system-reserved` (dành cho tiến trình hệ thống Linux) và `eviction-threshold` (ngưỡng an toàn chống sập ổ đĩa/RAM).

2. **Khi một Node bị rơi vào trạng thái `MemoryPressure = True`, Kubernetes xử lý như thế nào?**
   * *Trả lời:* Khi phát hiện áp lực bộ nhớ, kubelet trên node đó sẽ ngay lập tức:
     * Chặn không cho Kube-scheduler lập lịch thêm bất kỳ Pod mới nào vào node này.
     * Bắt đầu quy trình thu hồi bộ nhớ (Eviction): kubelet sẽ chấm dứt (terminate) các Pod theo thứ tự ưu tiên thấp nhất dựa trên `QoS Class` (ưu tiên trục xuất BestEffort trước, sau đó đến Burstable, và cuối cùng mới là Guaranteed).

3. **Sự khác biệt giữa `kubectl cordon` và `kubectl drain` là gì?**
   * *Trả lời:*
     * `kubectl cordon`: Chỉ thực hiện **đóng cửa** không nhận Pod mới (`SchedulingDisabled`), còn các Pod đang chạy trên node vẫn tiếp tục hoạt động bình thường, không bị tắt hay di chuyển.
     * `kubectl drain`: Trước tiên tự động gọi `cordon`, sau đó gửi tín hiệu rút cạn kết nối an toàn (Graceful Termination) để **trục xuất (evict)** toàn bộ các Pod đang chạy sang các Worker Node khác trong cụm để bạn có thể tắt máy chủ một cách an toàn.
