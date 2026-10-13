# Lab 36: Thu Thập Metrics Và Logs Từ Hạ Tầng

Trong kiến trúc giám sát và vận hành hệ thống hiện đại, **Infrastructure Observability (Khả năng quan sát hạ tầng)** là nền móng bảo vệ tính sẵn sàng của toàn bộ hệ sinh thái dịch vụ. Nếu như ở Lab 35, chúng ta đã gắn cảm biến vào mã nguồn ứng dụng để đo đạc chỉ số nghiệp vụ (RPS, lỗi 500, độ trễ API), thì ở bài lab này, chúng ta sẽ làm chủ việc thu thập và phân tích dữ liệu telemetry từ tầng phần cứng, nhân hệ điều hành Linux và hệ thống nhật ký máy chủ.

Sự cố hạ tầng như cạn kiệt dung lượng đĩa (Disk Full), nghẽn cổ chai I/O đọc/ghi, rò rỉ bộ nhớ dẫn đến cơ chế Out-Of-Memory (OOM) Killer tiêu diệt tiến trình, hoặc các đợt tấn công dò quét SSH đều để lại dấu vết rõ ràng qua **Metrics hạ tầng** và **System Logs**. Việc hợp nhất hai luồng dữ liệu này giúp kỹ sư DevOps nhanh chóng khoanh vùng nguyên nhân gốc rễ (Root Cause Analysis - RCA).

---

## 1. Kiến Trúc Giám Sát Hạ Tầng Tổng Thể

Hệ thống trong bài thực hành kết hợp hai giải pháp chuẩn mực mã nguồn mở từ hệ sinh thái Cloud Native Computing Foundation (CNCF) và Grafana:

```text
 ┌────────────────────────────────────────────────────────────────────────┐
 │                         LINUX HOST / INFRASTRUCTURE                    │
 │                                                                        │
 │  ┌───────────────────────┐                  ┌───────────────────────┐  │
 │  │     NODE EXPORTER     │                  │   PROMTAIL SHIPPER    │  │
 │  │                       │                  │                       │  │
 │  │ • Thu thap CPU, RAM   │                  │ • Doc tệp nhat ky     │  │
 │  │ • Disk I/O, Network   │                  │   /var/log/...        │  │
 │  │ • Expose HTTP :9100   │                  │ • Gan nhan (Labels)   │  │
 │  └───────────┬───────────┘                  └───────────┬───────────┘  │
 └──────────────┼──────────────────────────────────────────┼──────────────┘
                │ HTTP GET                                 │ HTTP POST
                │ /metrics (Pull)                          │ /push (Push)
                ▼                                          ▼
 ┌──────────────────────────────┐              ┌──────────────────────────────┐
 │      PROMETHEUS SERVER       │              │         GRAFANA LOKI         │
 │                              │              │                              │
 │ • Scrape engine (Pull model) │              │ • Nhan va luu tru log stream │
 │ • Time-Series Database (TSDB)│              │ • Index theo nhan toi uu     │
 │ • Co che truy van PromQL     │              │ • Co che truy van LogQL      │
 │ • Web UI / API: Cong 9090    │              │ • HTTP API: Cong 3100        │
 └──────────────────────────────┘              └──────────────────────────────┘
```

---

## 2. Mục Tiêu Bạn Cần Đạt Được Trong Bài Lab Này

1. **Triển khai Prometheus Node Exporter:** Vận hành Node Exporter an toàn, hiểu rõ cách thức thu thập số liệu phần cứng và khảo sát các metric hệ điều hành chuẩn mực.
2. **Cấu hình Prometheus Scrape & Phân tích PromQL:** Thiết lập Scrape Job giám sát host và viết các câu lệnh truy vấn PromQL tính toán tỷ lệ sử dụng CPU, bộ nhớ RAM khả dụng, tải hệ thống Load Average và thông lượng đọc/ghi đĩa.
3. **Triển khai Grafana Loki & Promtail:** Xây dựng trung tâm thu thập và quản lý nhật ký tập trung thế hệ mới, cấu hình Promtail Pipeline để đọc tệp nhật ký hạ tầng và chuyển tiếp sang Loki.
4. **Mô phỏng sự cố & Truy vấn chuyên sâu với LogQL:** Kích hoạt các sự kiện cảnh báo và lỗi hệ thống, thực hiện truy vấn bóc tách log theo bộ lọc từ khóa, biểu thức chính quy (Regex) và chuyển đổi log thành chỉ số thống kê (Log-to-Metrics).

Nhấn **Next** để bắt đầu bước đầu tiên!
