# Xin Chúc Mừng! Bạn Đã Làm Chủ PromQL

Bạn đã hoàn thành xuất sắc bài thực hành **Lab 41: Phân Tích Hệ Thống Bằng PromQL** và trang bị cho mình tư duy truy vấn chuỗi thời gian của một kỹ sư SRE thực thụ.

---

## 1. Bảng Tra Cứu Nhanh Các Hàm PromQL Cốt Lõi (Cheat Sheet)

| Hàm / Toán tử | Đầu vào | Mục đích sử dụng | Ví dụ thực tế |
| :--- | :--- | :--- | :--- |
| **`rate(v[range])`** | Range Vector | Tính tốc độ biến thiên trung bình trên giây (cho Counter) | `rate(http_requests_total[5m])` |
| **`irate(v[range])`** | Range Vector | Tính tốc độ tức thời giữa 2 điểm mẫu gần nhất (bắt biến động nhanh) | `irate(node_cpu_seconds_total[1m])` |
| **`histogram_quantile(φ, b)`** | Bucket Vector | Tính giá trị bách phân vị $\phi$ (p90, p95, p99 Latency) | `histogram_quantile(0.95, sum(...) by (le))` |
| **`topk(k, v)`** | Instant Vector | Lọc ra $k$ chuỗi thời gian có giá trị lớn nhất | `topk(5, rate(http_requests_total[5m]))` |
| **`sum by (label)`** | Instant Vector | Gộp tổng theo một hoặc nhiều nhãn cụ thể | `sum by (status, path) (...)` |

---

## 2. Bài Học SRE Kinh Điển

1. **Không bao giờ dùng average latency:** Luôn sử dụng `histogram_quantile` với ngưỡng p95 hoặc p99 để phát hiện các request bị nghẽn (Tail Latency).
2. **Quy tắc tính CPU chuẩn:** Luôn tính từ thời gian nhàn rỗi `mode="idle"` rồi lấy 100% trừ đi, không cộng dồn các mode hoạt động vì có thể sót trạng thái steal/guest/softirq.
3. **Phân biệt rạch ròi Vector:** Instant Vector để hiển thị và vẽ biểu đồ; Range Vector làm tham số đầu vào cho các hàm tính toán biến thiên (`rate`, `increase`).

---

## 3. Bước Tiếp Theo

Các câu truy vấn bạn vừa viết chính là **"nguyên liệu vàng"** để xây dựng giao diện trực quan hóa. Không ai đọc số liệu dạng text thô trên Production!

Hãy cùng bước sang bài thực hành tiếp theo:
👉 **"Lab 42: Xây Dựng Monitoring Dashboard Với Grafana"** — kết nối Grafana với Prometheus và biến các câu truy vấn PromQL này thành các Panel, biểu đồ Gauge, Time-series và Heatmap tuyệt đẹp!
