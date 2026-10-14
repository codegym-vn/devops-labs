# Lab 40: Cấu Hình Prometheus Và Exporters

Trong giám sát hạ tầng và ứng dụng hiện đại, **Prometheus** (dự án mã nguồn mở trực thuộc CNCF) là tiêu chuẩn công nghiệp (de facto standard) cho việc thu thập và lưu trữ dữ liệu chuỗi thời gian (**Time-series Database - TSDB**).

Khác với các hệ thống giám sát truyền thống theo cơ chế Push (từng máy chủ tự động đẩy dữ liệu lên máy chủ trung tâm), Prometheus tiên phong áp dụng mô hình **Pull-based**: Prometheus Server chủ động định kỳ gửi HTTP GET request đến các điểm cuối (endpoints) mang tên **/metrics** để kéo dữ liệu về.

---

## 1. Exporter Là Gì & Tại Sao Cần Exporter?

Phần lớn các phần mềm và hệ điều hành (như Linux Kernel, Nginx, MySQL, Redis, HAProxy) được thiết kế từ trước khi Prometheus ra đời và không có sẵn endpoint `/metrics` theo chuẩn Prometheus. 

Để giải quyết bài toán này, cộng đồng tạo ra **Exporters**:
- Exporter đóng vai trò như một "thông dịch viên" (Proxy/Agent).
- Nó kết nối vào hệ điều hành hoặc phần mềm mục tiêu để đọc các chỉ số nội bộ (qua `/proc`, lệnh `INFO`, Socket, hoặc API).
- Sau đó, Exporter chuyển đổi dữ liệu thô thành định dạng văn bản chuẩn **OpenMetrics** và mở ra một HTTP port để Prometheus cào (Scrape).

```text
 ┌──────────────────────────────────────────────────────────────────────────────────┐
 │                                 CÁC NGUỒN DỮ LIỆU                                │
 │                                                                                  │
 │   ┌──────────────────────────┐             ┌──────────────────────────┐          │
 │   │    LINUX HOST / KERNEL   │             │       REDIS DATABASE     │          │
 │   │  CPU, RAM, Disk, Network │             │   Memory, Clients, Ops   │          │
 │   └────────────┬─────────────┘             └────────────┬─────────────┘          │
 │                │ Đọc /proc, sysfs                       │ Đọc INFO command       │
 │                ▼                                        ▼                        │
 │   ┌──────────────────────────┐             ┌──────────────────────────┐          │
 │   │      NODE EXPORTER       │             │      REDIS EXPORTER      │          │
 │   │      HTTP Port: 9100     │             │      HTTP Port: 9121     │          │
 │   └────────────┬─────────────┘             └────────────┬─────────────┘          │
 └────────────────┼────────────────────────────────────────┼────────────────────────┘
                  │                                        │
                  │ HTTP GET /metrics (Scrape 5s)          │ HTTP GET /metrics
                  ▼                                        ▼
 ┌──────────────────────────────────────────────────────────────────────────────────┐
 │                        PROMETHEUS SERVER (PORT 9090)                             │
 │                                                                                  │
 │   [Retrieval / Scrape Engine]  ──►  [TSDB Storage]  ──►  [HTTP API & Web UI]     │
 │   • Quản lý danh sách Targets       • Lưu trữ Time-Series • Đánh giá Targets UP  │
 │   • prometheus.yml                  • Nén dữ liệu block   • Endpoint /-/reload   │
 └──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Mục Tiêu Bạn Cần Đạt Được Trong Bài Lab Này

1. **Vận hành Node Exporter:** Triển khai bộ thu thập chỉ số phần cứng/hệ điều hành Linux và giải phẫu định dạng OpenMetrics text format.
2. **Triển khai Service Exporter:** Cấu hình Redis Exporter kết nối với CSDL Redis để hiểu cách giám sát dịch vụ bên thứ ba.
3. **Thiết kế cấu hình `prometheus.yml`:** Khởi chạy Prometheus Server, cấu hình Scrape Targets đa nguồn và bổ sung các nhãn quản trị (Metadata Labels).
4. **Làm chủ kỹ thuật Hot-reload cấu hình:** Nạp lại cấu hình động không làm gián đoạn hệ thống TSDB (Zero-downtime Lifecycle Management).

Nhấn **Start** để bước vào phần thực hành!
