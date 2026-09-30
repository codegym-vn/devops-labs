# Bước 2: Phân Tích Chuyên Sâu Trạng Thái Node (Conditions & Allocatable)

Trong bước này, bạn sẽ đi sâu vào kiểm tra sức khỏe của máy chủ Worker (`node01`), phân tích 4 điều kiện cốt tử (**Node Conditions**) và phân biệt giữa dung lượng vật lý (**Capacity**) với tài nguyên thực tế dành cho ứng dụng (**Allocatable**).

---

## 1. Lý Thuyết: Điều Kiện Sức Khỏe & Quản Lý Tài Nguyên

### 1.1 — Bốn Điều Kiện Vận Hành Cốt Tử (Node Conditions)
Kubelet liên tục theo dõi và báo cáo tình trạng của Node về API Server thông qua 4 chỉ số:

| Điều Kiện (Condition) | Ý Nghĩa Vận Hành | Trạng Thái Mong Muốn |
| :--- | :--- | :---: |
| **Ready** | Node khỏe mạnh và sẵn sàng tiếp nhận điều phối Pod mới | **True** |
| **MemoryPressure** | Bộ nhớ RAM trên Node bị thiếu hụt nghiêm trọng | **False** |
| **DiskPressure** | Dung lượng ổ đĩa gốc sắp cạn kiệt | **False** |
| **PIDPressure** | Số lượng tiến trình (Process ID) vượt quá ngưỡng an toàn | **False** |

> [!NOTE]
> Một Node đạt chuẩn Production lý tưởng khi và chỉ khi: `Ready = True` và tất cả các chỉ số cảnh báo áp lực còn lại đều là `False`.

---

### 1.2 — Capacity vs Allocatable: Bài Toán Đặt Chỗ Tài Nguyên
Trên bất kỳ máy chủ nào:
* **Capacity (Dung lượng tổng):** Toàn bộ CPU, RAM, ổ đĩa vật lý của máy chủ.
* **Allocatable (Dung lượng khả dụng):** Lượng tài nguyên thực tế mà bộ lập lịch (Kube-scheduler) được phép phân bổ cho các Pods của bạn:

```text
Allocatable = Capacity - (Kube-Reserved + System-Reserved + Eviction Threshold)
```

Kubernetes chủ động giữ lại một phần CPU và RAM để phục vụ hệ điều hành (systemd, sshd) và các đặc vụ nội bộ (kubelet, containerd), tránh tình trạng Pod ngốn 100% tài nguyên làm sập máy chủ.

---

## 2. Thực Hành

### 2.1 — Mổ xẻ chi tiết thông số của Worker Node (`describe node`)

Chạy lệnh kiểm tra toàn diện máy chủ `node01`:

```bash
kubectl describe node node01
```{{exec}}

Hãy cuộn terminal và quan sát các khối quan trọng:
1. **Conditions:** Xác nhận trạng thái của `Ready`, `MemoryPressure`, `DiskPressure`, `PIDPressure`.
2. **Capacity & Allocatable:** So sánh các giá trị `cpu`, `memory`, `ephemeral-storage` và `pods`.
3. **Non-terminated Pods:** Danh sách các Pod hệ thống đang chạy ngầm trên node này (như `kube-proxy`, CNI pod).

---

### 2.2 — Truy vấn siêu tốc bằng biểu thức JSONPath

Trong tự động hóa giám sát hoặc script CI/CD, kỹ sư thường không đọc lệnh describe thủ công mà trích xuất trực tiếp thông số qua `-o jsonpath`:

1. **Kiểm tra trạng thái Ready của node01:**
   ```bash
   kubectl get node node01 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'
   echo ""
   ```{{exec}}
   *(Kết quả trả về: `True`).*

2. **Kiểm tra lượng RAM khả dụng (Allocatable Memory):**
   ```bash
   kubectl get node node01 -o jsonpath='{.status.allocatable.memory}'
   echo ""
   ```{{exec}}

3. **Kiểm tra số lượng CPU Cores khả dụng:**
   ```bash
   kubectl get node node01 -o jsonpath='{.status.allocatable.cpu}'
   echo ""
   ```{{exec}}

---

## 3. Bài Tập Thử Thách

> [!TIP] Hãy hoàn thành các thao tác hướng dẫn ở trên trước khi thực hiện thử thách tự lập này.

Mỗi Node trong Kubernetes đều có giới hạn số lượng Pod tối đa được phép chạy đồng thời để đảm bảo an toàn tài nguyên mạng và tính ổn định của Kubelet (mặc định trong chuẩn Kubeadm thường là 110 pods).

**Yêu cầu:**
1. Sử dụng bộ lọc trích xuất `jsonpath` kết hợp với lệnh kiểm tra thông tin node để lấy đúng giá trị số lượng Pods khả dụng tối đa trên `node01` (trường `.status.allocatable.pods`).
2. Chuyển hướng lưu kết quả đầu ra đó vào tệp `/tmp/node01-pods.txt`.
3. Kiểm tra lại nội dung tệp bằng lệnh đọc tệp để đảm bảo giá trị ghi nhận là một con số nguyên (ví dụ: `110`).

**Gợi ý:**
- Cú pháp tương tự như khi bạn trích xuất RAM hay CPU ở mục 2.2 (`-o jsonpath='{...}'`), chỉ cần đổi đường dẫn trường JSON thành `{.status.allocatable.pods}`.
- Kết hợp toán tử điều hướng `>` để ghi kết quả trực tiếp vào `/tmp/node01-pods.txt`.

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
