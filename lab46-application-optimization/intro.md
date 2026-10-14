# Lab 46: [Case Study] Phân Tích Báo Cáo & Tối Ưu Tầng Ứng Dụng

Chào mừng bạn đến với bài thực hành Case Study **Phân Tích Báo Cáo & Tối Ưu Tầng Ứng Dụng (Application Performance Optimization)**!

Trong kỹ nghệ độ tin cậy hệ thống (SRE), khi một hệ thống bị quá tải hoặc phản hồi chậm, phản xạ đầu tiên của nhiều kỹ sư thiếu kinh nghiệm là yêu cầu *"mua thêm máy chủ hoặc nâng cấp CPU/RAM"* (Vertical Scaling). Tuy nhiên, nếu nguyên nhân gốc rễ nằm ở thuật toán kém hoặc truy vấn dữ liệu thiếu hiệu quả, việc bổ sung phần cứng chỉ làm tăng chi phí hạ tầng (Cloud Bill) mà không giải quyết được nút thắt cổ chai.

Theo nguyên lý Pareto (80/20), **tối ưu hóa tầng ứng dụng (Application & Database Layer) thường mang lại 80% hiệu quả cải thiện với 0 đồng chi phí phần cứng bổ sung**.

---

### Mô Hình Cache-Aside (Lazy Loading)

Một trong những mô hình kinh điển và mạnh mẽ nhất để giải phóng áp lực cho cơ sở dữ liệu và tăng tốc độ phản hồi là **Cache-Aside Pattern**:

```mermaid
flowchart TD
    CLIENT["Client / Web Browser"] -->|1. GET /api/catalog| APP["Application Server"]
    APP -->|2. Kiểm tra dữ liệu| CACHE{"Có trong Cache?<br/>(Redis / RAM)"}

    CACHE -->|YES: Cache HIT<br/>(Độ trễ < 2ms)| RETURN["Trả về dữ liệu ngay lập tức"]
    RETURN --> CLIENT

    CACHE -->|NO: Cache MISS| DB[("Cơ Sở Dữ Liệu<br/>(Query đắt đỏ ~140ms)")]
    DB -->|3. Đọc dữ liệu thô| APP
    APP -->|4. Lưu vào Cache với TTL=60s| CACHE
    APP -->|5. Trả về kết quả| CLIENT
```

* **Cache HIT:** Dữ liệu đã có sẵn trong bộ nhớ đệm, trả về tức thời trong vài mili-giây, hoàn toàn không chạm vào Database.
* **Cache MISS:** Lần đầu tiên truy vấn, ứng dụng đọc từ Database, đồng thời ghi lại vào Cache với thời gian sống xác định (TTL - Time-To-Live). Các request tiếp theo của hàng nghìn người dùng khác sẽ trở thành Cache HIT.

---

### Tình Huống Case Study

Bạn được giao nhiệm vụ tối ưu hóa dịch vụ **Catalog Service** (`:8080`):
- **Triệu chứng:** Người dùng phàn nàn khi xem danh mục sản phẩm trang bị tải chậm. Khi chạy kiểm thử tải, độ trễ p95 lên tới 400ms và máy chủ chỉ phục vụ được khoảng ~50 requests/giây.
- **Nhiệm vụ của bạn:**
  1. Đọc và phân tích báo cáo chẩn đoán hiệu năng ban đầu (`initial-report.json`).
  2. Thực hiện đo lường chuẩn xác trước khi can thiệp (Benchmark Before).
  3. Triển khai mô hình Cache-Aside để giảm tải cho tác vụ đọc dữ liệu.
  4. Thực hiện đo lường lại (Benchmark After) và lập báo cáo so sánh đối chiếu định lượng để chứng minh hiệu quả cải thiện.

Nhấn **Start** để bước vào quy trình điều tra và tối ưu hóa hệ thống!
