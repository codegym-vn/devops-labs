# Bước 1: Tự Động Hóa Kết Nối Prometheus Bằng Grafana Provisioning

Trong thực tế vận hành hạ tầng Cloud-Native (Kubernetes, Docker Swarm), việc đăng nhập giao diện Web và thao tác bấm chuột "Add Data source" thủ công là hành vi **ClickOps** tiềm ẩn rủi ro và không thể tái tạo (non-reproducible).

Grafana cung cấp cơ chế **Provisioning** — tự động quét và nạp cấu hình nguồn dữ liệu (Data Source) từ các tệp YAML đặt trong thư mục `/etc/grafana/provisioning/datasources/`.

---

### 1. Cấu Trúc Tệp Cấu Hình Datasource Provisioning

Một tệp cấu hình Data Source chuẩn cho Prometheus có cấu trúc như sau:

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true
    editable: true
    jsonData:
      httpMethod: POST
      timeInterval: 2s
```

**Giải thích các trường quan trọng:**
- **`apiVersion: 1`**: Phiên bản chuẩn của cú pháp Provisioning trong Grafana.
- **`name: Prometheus`**: Tên hiển thị của Data Source trên các bảng điều khiển.
- **`type: prometheus`**: Loại plugin tích hợp (Grafana hỗ trợ sẵn Prometheus, Loki, Jaeger, InfluxDB, Elasticsearch...).
- **`access: proxy`**: Mọi truy vấn từ trình duyệt sẽ đi qua Grafana Backend Server làm proxy trước khi tới Prometheus (bảo mật và tránh lỗi CORS).
- **`url: http://localhost:9090`**: Địa chỉ mạng nội bộ của máy chủ Prometheus.
- **`isDefault: true`**: Đặt làm nguồn dữ liệu mặc định khi tạo mới các biểu đồ Panel.
- **`editable: true`**: Vẫn cho phép kỹ sư xem và kiểm tra tham số trên giao diện Web UI nếu cần.

---

### 2. Thực Hành Tạo Cấu Hình Datasource

Khởi tạo tệp cấu hình `/root/grafana-lab/provisioning/datasources/prometheus-datasource.yml`:

```bash
cat << 'EOF' > /root/grafana-lab/provisioning/datasources/prometheus-datasource.yml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true
    editable: true
    jsonData:
      httpMethod: POST
      timeInterval: 2s
EOF
```

---

### 3. Nạp Cấu Hình & Xác Minh Qua Grafana REST API

Để Grafana cập nhật nguồn dữ liệu mới mà không cần can thiệp giao diện, bạn có thể gọi API Provisioning Reload của Grafana hoặc khởi động lại container:

```bash
# 1. Gọi Reload API của Grafana Provisioning
curl -s -X POST -u admin:admin http://localhost:3000/api/admin/provisioning/datasources/reload

# 2. Hoặc khởi động lại nhẹ container nếu cần nạp lại từ đầu
docker restart grafana
sleep 3
```

Kiểm tra danh sách Data Sources đã được nạp thành công qua Grafana HTTP API:

```bash
curl -s -u admin:admin http://localhost:3000/api/datasources | jq .
```

Kết quả trả về sẽ hiển thị Data Source mang tên `Prometheus` trỏ tới `http://localhost:9090`.

Bạn cũng có thể mở giao diện Web tại `http://localhost:3000` (đăng nhập `admin`/`admin` hoặc truy cập trực tiếp nếu đã bật Anonymous) và vào mục **Connections -> Data sources** để thấy nguồn dữ liệu màu xanh hiển thị trạng thái hoạt động tốt.

---

### 4. Yêu Cầu Hoàn Thành Bước 1

1. Tệp `/root/grafana-lab/provisioning/datasources/prometheus-datasource.yml` được tạo với cấu hình đầy đủ.
2. Gọi API `http://localhost:3000/api/datasources` trả về ít nhất 1 Data Source hợp lệ loại `prometheus`.

Sau khi hoàn tất, nhấn **Check** để hệ thống tự động kiểm tra và chấm điểm Bước 1.
