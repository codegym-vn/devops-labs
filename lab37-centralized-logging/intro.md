# Lab 37: Xây Dựng Hệ Thống Centralized Logging

Trong kiến trúc hệ thống phân tán (Microservices & Multi-Node Cluster), mỗi dịch vụ ghi log vào các tệp tin hoặc container riêng lẻ. Khi một sự cố giao dịch xảy ra (ví dụ: khách hàng thanh toán bị trừ tiền nhưng không nhận được đơn hàng), kỹ sư vận hành sẽ phải SSH vào từng máy chủ, mở đồng thời hàng chục cửa sổ terminal và sử dụng lệnh **tail -f** hoặc **grep** thủ công. Cách tiếp cận phân mảnh này làm tăng đột biến thời gian phục hồi sự cố (MTTR) và hoàn toàn bất khả thi ở quy mô hàng trăm container.

Để giải quyết triệt để thách thức trên, các tổ chức công nghệ áp dụng mô hình **Centralized Logging (Hệ thống quản lý nhật ký tập trung)**: toàn bộ log từ Web Gateway, Backend Services, cơ sở dữ liệu và hệ điều hành được tự động thu thập, chuẩn hóa cấu trúc, gắn nhãn định danh và chuyển tiếp về một kho lưu trữ tập trung duy nhất theo thời gian thực.

---

## 1. Kiến Trúc Pipeline Centralized Logging Chuẩn Doanh Nghiệp

Hệ thống trong bài thực hành sử dụng **Fluent Bit** (dự án mã nguồn mở trực thuộc CNCF, được viết bằng C với hiệu năng xử lý hàng trăm nghìn log/giây và tiêu tốn chưa đến 50MB RAM) đóng vai trò tác tử thu thập và xử lý (Log Collector & Processor), kết hợp cùng **Grafana Loki** đóng vai trò kho lưu trữ nhật ký tập trung:

```text
 ┌──────────────────────────────────────────────────────────────────────────────────┐
 │                               NGUỒN PHÁT SINH NHẬT KÝ                            │
 │                                                                                  │
 │   ┌──────────────────────────┐             ┌──────────────────────────┐          │
 │   │      NGINX GATEWAY       │             │    ORDER MICROSERVICE    │          │
 │   │                          │             │                          │          │
 │   │  Access Log (Combined)   │             │  Application Log (JSON)  │          │
 │   └────────────┬─────────────┘             └────────────┬─────────────┘          │
 └────────────────┼────────────────────────────────────────┼────────────────────────┘
                  │                                        │
                  ▼                                        ▼
 ┌──────────────────────────────────────────────────────────────────────────────────┐
 │                         FLUENT BIT LOG PIPELINE PROCESSOR                        │
 │                                                                                  │
 │   [INPUT]  ──►  [PARSER]        ──►  [FILTER]          ──►  [ROUTING / OUTPUT]   │
 │   Tail tệp      Nginx Regex &        Record Modifier        Định tuyến theo Tag  │
 │   log apps      JSON Decoders        Gắn env, cluster       HTTP POST Push       │
 │                                      Che dữ liệu nhạy cảm                        │
 └───────────────────────────────────────────────────┬──────────────────────────────┘
                                                     │
                                                     ▼ HTTP Push /loki/api/v1/push
 ┌──────────────────────────────────────────────────────────────────────────────────┐
 │                    GRAFANA LOKI (CENTRALIZED LOG REPOSITORY)                     │
 │                                                                                  │
 │ • Lưu trữ các Log Stream nén theo chuỗi thời gian                                │
 │ • Index siêu nhẹ theo metadata labels (app, service, environment, datacenter)    │
 │ • Động cơ truy vấn LogQL bóc tách sự cố xuyên suốt đa tầng dịch vụ (Correlated)  │
 └──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Mục Tiêu Bạn Cần Đạt Được Trong Bài Lab Này

1. **Thiết kế Pipeline xử lý nhật ký với Fluent Bit:** Nắm vững chuỗi xử lý (Input, Parser, Filter, Output) để thu thập, chuẩn hóa định dạng (JSON & Nginx regex) và làm giàu metadata cho các luồng log phân tán.
2. **Vận hành cụm lưu trữ tập trung Grafana Loki & Định tuyến:** Cấu hình định tuyến Tag-based Routing trong Fluent Bit để phân loại và đẩy log đa nguồn về Loki theo từng stream dịch vụ logic.
3. **Truy vết sự cố xuyên tầng bằng LogQL:** Vận dụng LogQL để lọc lỗi và thực hiện kỹ thuật liên kết giao dịch (Correlated Tracing) qua mã **req_id** trên toàn bộ hệ thống.

Nhấn **Next** để bắt đầu bước đầu tiên!
