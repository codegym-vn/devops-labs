# Chúc Mừng Bạn Đã Hoàn Thành Lab 37!

Bạn đã hoàn thành xuất sắc bài thực hành **Xây Dựng Hệ Thống Centralized Logging Pipeline** chuẩn doanh nghiệp.

---

### Những Năng Lực Cốt Lõi Bạn Đã Làm Chủ:

1. **Kiến trúc Centralized Logging hiện đại:** Hiểu sâu tại sao mô hình lưu trữ tập trung là điều kiện tiên quyết đối với hệ thống vi dịch vụ (Microservices), giải quyết triệt để vấn đề phân mảnh nhật ký cục bộ.
2. **Làm chủ Fluent Bit Pipeline:** Xây dựng thành thạo chuỗi xử lý gồm Input (thu thập tệp đa nguồn), Parser (giải mã chuỗi văn bản Nginx và đối tượng JSON), Filter (làm giàu metadata hạ tầng) và Routing (định tuyến đa luồng theo Match Tag).
3. **Quản trị phân vùng Log Stream trong Loki:** Phân chia các dòng log theo nhãn dịch vụ logic (service, type, cluster) thay vì nén thô, giúp tăng tốc độ truy vấn lên hàng chục lần.
4. **Truy vết sự cố liên kết đa tầng với LogQL:** Thực hiện kỹ thuật Correlated Tracing để tái hiện toàn bộ chuỗi hành vi của một yêu cầu từ Gateway qua Backend chỉ bằng một truy vấn duy nhất.

---

### Bảng Tra Cứu Nhanh Pipeline & Cú Pháp (Cheat Sheet)

| Thành Phần / Tác Vụ | Cấu Hình / Lệnh Mẫu | Ý Nghĩa Thực Tiễn |
|---|---|---|
| **Fluent Bit Input** | [INPUT] Name tail, Path /var/log/*.log | Đọc liên tục các tệp nhật ký ứng dụng |
| **JSON Parser** | [PARSER] Format json | Tự động bóc tách các trường JSON thành key-value |
| **Regex Parser** | [PARSER] Format regex, Regex ^(?<remote>... | Cấu trúc hóa chuỗi log phi cấu trúc của Web Server |
| **Record Modifier** | [FILTER] Name record_modifier, Record env prod | Bổ sung metadata quản trị vào từng bản ghi |
| **Loki Output Routing** | [OUTPUT] Name loki, Match app.*, Labels service=order-api | Định tuyến thông minh theo nhãn ứng dụng |
| **Truy vết Correlated** | {job="centralized-logging"} \|= "req_1001" | Tìm kiếm mọi log liên quan đến một request ID |
| **Lọc log lỗi 500 Nginx** | {service="nginx-gateway"} \|= " 500 " | Lọc tức thì các request bị sập từ cổng vào |
| **Đếm tổng lỗi hệ thống** | count_over_time({job="centralized-logging"} \|= "error" [1h]) | Thống kê số lượng log lỗi toàn hệ thống |

---

Bạn đã sẵn sàng để tiếp tục tiến xa hơn trong lộ trình làm chủ Observability và Site Reliability Engineering!
