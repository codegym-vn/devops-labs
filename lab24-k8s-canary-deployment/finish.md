# Hoàn Thành Bài Lab 24: K8s Canary Deployment

Xin chúc mừng! Bạn đã hoàn thành xuất sắc bài thực hành triển khai ứng dụng tự động theo chiến lược **Canary Deployment** trên cụm Kubernetes.

---

## 1. Tổng Kết Các Kỹ Năng Đã Đạt Được

1. **Điều Phối Lưu Lượng Bằng Kubernetes Service:**
   * Hiểu rõ cơ chế bộ chọn nhãn (`selector` và `labels`) giúp chia sẻ lưu lượng giữa nhiều Deployment khác nhau mà không cần cài đặt thêm phần mềm bên ngoài.
   * Tính toán và kiểm soát tỷ lệ phần trăm lưu lượng gửi tới phiên bản mới dựa trên tỷ số lượng bản sao Pod.

2. **Tự Động Hóa Kiểm Thử & Quality Gate:**
   * Xây dựng kịch bản kiểm tra tự động đo lường tỷ lệ lỗi (Error Rate) và mã phản hồi HTTP.
   * Thiết lập cơ chế quyết định thăng cấp (Promotion Gate) khách quan dựa trên dữ liệu phản hồi thực tế thay vì cảm tính.

3. **Quy Trình Thăng Cấp Không Gián Đoạn (Zero-Downtime Promotion):**
   * Áp dụng Rolling Update trên Deployment Stable để nâng cấp phiên bản cho 100% người dùng.
   * Dọn dẹp tài nguyên Canary gọn gàng sau khi hoàn tất.

4. **Khả Năng Cô Lập Rủi Ro & Rollback Tức Thì:**
   * Chứng minh thực tế rằng sự cố của phiên bản mới không làm ảnh hưởng đến người dùng đang sử dụng phiên bản ổn định.
   * Kích hoạt thao tác khôi phục trạng thái an toàn chỉ với một thao tác duy nhất.

---

## 2. So Sánh Các Chiến Lược Triển Khai Trong Thực Tế

| Tiêu chí | Recreate (Big Bang) | Rolling Update | Blue/Green Deployment | Canary Deployment |
|---|---|---|---|---|
| **Gián đoạn (Downtime)** | Có downtime | Không downtime | Không downtime | Không downtime |
| **Chi phí hạ tầng** | Rất thấp (1x) | Thấp (1x + buffer) | Cao (2x tài nguyên) | Rất thấp (1x + 1 Pod) |
| **Mức độ rủi ro** | Rất cao | Trung bình | Thấp | Rất thấp (cô lập rủi ro) |
| **Khả năng Rollback** | Chậm | Phải rollout undo | Rất nhanh (đổi router) | Rất nhanh (xóa Canary) |
| **Kiểm thử trên người dùng thật** | Không | Không | Không | **Có (mục tiêu chính)** |

---

Bạn có thể tiếp tục tự do khám phá môi trường hoặc đóng kịch bản bài học. Chúc bạn ứng dụng thành công các kiến thức này vào công việc vận hành DevOps thực tế!
