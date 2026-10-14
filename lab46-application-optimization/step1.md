# Bước 1: Khảo Sát Hiện Trạng & Phân Tích Performance Report

Trong kỹ nghệ hiệu năng, nguyên tắc bất di bất dịch trước khi đụng vào mã nguồn là: **"Không tối ưu hóa khi chưa có số liệu đo đạc (Never optimize without data)"**. Bạn cần bắt đầu bằng việc đọc báo cáo chẩn đoán và khảo sát hành vi hiện tại của ứng dụng.

---

### 1. Đọc Báo Cáo Chẩn Đoán Hiệu Năng Ban Đầu

Đọc tệp báo cáo chẩn đoán tại `/root/app-opt-lab/reports/initial-report.json`:

```bash
cat /root/app-opt-lab/reports/initial-report.json | jq .
```

*Phân tích thông tin từ báo cáo:*
* **Vị trí nút thắt:** Endpoint `/api/catalog` đang gánh chịu thời gian truy vấn và serialize dữ liệu trung bình lên tới **140ms** cho mỗi lượt gọi.
* **Hậu quả:** Khi có 20 người dùng đồng thời, các worker threads đều bị giữ chặt trong trạng thái chờ I/O, khiến hàng đợi request bị tắc nghẽn và CPU tiêu hao vô ích cho việc render lại các mẩu tin trùng lặp.
* **Khuyến nghị ban đầu:** Triển khai tầng lưu đệm (Caching) theo mô hình Cache-Aside với thời gian sống (TTL) 60 giây.

---

### 2. Khảo Sát Trực Tiếp Phản Hồi Của API

Gửi một request đơn lẻ tới API `/api/catalog` và quan sát các HTTP headers trả về:

```bash
curl -i -s http://localhost:8080/api/catalog | head -n 15
```

Bạn sẽ thấy header:
```text
X-Cache-Status: BYPASS
```
Giá trị `BYPASS` biểu thị rằng dữ liệu đang được truy vấn trực tiếp và hoàn toàn bỏ qua tầng bộ nhớ đệm.

---

### 3. Kiểm Tra Cấu Hình Môi Trường Ứng Dụng

Xem tệp cấu hình môi trường tại `/root/app-opt-lab/config/app.env`:

```bash
cat /root/app-opt-lab/config/app.env
```

*Nội dung hiện tại:*
```text
PORT=8080
CACHE_ENABLED=false
CACHE_TTL_SECONDS=60
```
Tùy chọn `CACHE_ENABLED` hiện đang được đặt là `false`.

Sau khi khảo sát xong hiện trạng hệ thống và hiểu rõ nguyên nhân gây chậm, nhấn **Check** để hoàn thành Bước 1!
