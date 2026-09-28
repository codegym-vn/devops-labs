# Bước 3: Kiểm Tra Target Health & Phân Tích Thuật Toán Cân Bằng Tải

Trong bước này, bạn sẽ sử dụng **AWS CLI** để giám sát trạng thái sức khỏe (**Target Health**) của các máy chủ và phân tích cách thức **Application Load Balancer** điều phối lưu lượng.

---

## 1. Lý Thuyết: Cơ Chế Health Check & Thuật Toán Phân Tải

### 1.1 — Vòng đời kiểm tra sức khỏe (Health Check Lifecycle)
ALB định kỳ gửi request HTTP `GET /health` tới từng máy chủ:
* **Healthy (Khỏe mạnh):** Máy chủ trả về mã HTTP `200 OK`. ALB tiếp tục chuyển tiếp lưu lượng người dùng tới máy này.
* **Unhealthy (Bất thường):** Nếu máy chủ phản hồi lỗi (HTTP 500) hoặc timeout trong `2` lần liên tiếp (`UnhealthyThreshold = 2`), ALB lập tức cô lập máy chủ này ra khỏi danh sách phục vụ.
* **Tự phục hồi (Self-healing):** Auto Scaling Group sẽ nhận diện instance bị `unhealthy` từ ALB, tự động hủy instance lỗi và sinh ra một instance mới toanh thay thế.

```
       [ ALB Health Check Ping: GET /health ]
                      │
        ┌─────────────┴─────────────┐
        ▼ (HTTP 200 OK)             ▼ (Timeout / HTTP 500)
┌──────────────┐            ┌──────────────┐
│  Instance 1  │            │  Instance 2  │
│  [ HEALTHY ] │            │ [UNHEALTHY]  │
└──────┬───────┘            └──────┬───────┘
       │                           │
  Tiếp tục nhận             Bị cô lập ngay!
  traffic người dùng        ASG sẽ thay thế
```

### 1.2 — Thuật toán điều phối lưu lượng
* **Round Robin (Mặc định):** Phân bổ tuần tự đều đặn các request theo vòng tròn (Request 1 ➔ Instance A, Request 2 ➔ Instance B).
* **Least Outstanding Requests (LOR):** Chuyển tiếp request mới tới máy chủ nào đang xử lý ít request nhất (tối ưu cho các tác vụ tính toán nặng không đều).

---

## 2. Thực Hành

Tải lại các biến môi trường:

```bash
source /tmp/lab-env.sh
```{{exec}}

---

### 3.1 — Kiểm Tra Trạng Thái Sức Khỏe Các Mục Tiêu (Target Health)

Chạy lệnh kiểm tra xem các máy ảo do ASG tạo ra đã xuất hiện trong Target Group hay chưa:

```bash
aws elbv2 describe-target-health \
  --target-group-arn $TG_ARN \
  --query 'TargetHealthDescriptions[].[Target.Id, Target.Port, TargetHealth.State, TargetHealth.Reason]' \
  --output table
```{{exec}}

> [!NOTE]
> Khi mới khởi động, trạng thái có thể là `initial` (đang trong quá trình kiểm tra lần đầu) trước khi chuyển thành `healthy`.

---

### 3.2 — Khám Phá Cấu Hình Thuật Toán Cân Bằng Tải Của Target Group

Kiểm tra các thuộc tính nâng cao của Target Group (bao gồm thuật toán cân bằng tải và tính năng duy trì phiên làm việc `stickiness`):

```bash
aws elbv2 describe-target-group-attributes \
  --target-group-arn $TG_ARN \
  --query 'Attributes[?Key==`load_balancing.algorithm.type` || Key==`stickiness.enabled`]' \
  --output table
```{{exec}}

Quan sát bảng: Bạn sẽ thấy `load_balancing.algorithm.type` mặc định là `round_robin`.

---

## 3. Bài Tập Thử Thách

**Yêu cầu:** Lấy danh sách toàn bộ ID của các máy ảo đang được đăng ký làm mục tiêu (Target IDs) và xác nhận số lượng mục tiêu hiện tại:

```bash
REGISTERED_TARGETS=$(aws elbv2 describe-target-health \
  --target-group-arn $TG_ARN \
  --query 'TargetHealthDescriptions[].Target.Id' \
  --output text)

echo "Các mục tiêu đã đăng ký: $REGISTERED_TARGETS"
```{{exec}}

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
