# Bước 1: Khởi Chạy SonarQube Server & Kiểm Tra Trạng Thái Sẵn Sàng

SonarQube Server bao gồm 3 thành phần chính chạy bên trong container: Web Server giao diện người dùng, công cụ tìm kiếm Elasticsearch và Compute Engine (CE) xử lý báo cáo phân tích mã nguồn.

Ở bước này, bạn sẽ tự tay khởi chạy container SonarQube Server và theo dõi tiến trình khởi động.

---

### 1. Khởi chạy Container SonarQube Server

Thực hiện lệnh kéo và chạy SonarQube Community Edition trên cổng `9000`:

```bash
docker run -d --name sonarqube -p 9000:9000 sonarqube:lts-community
```{{exec}}

Quan sát tiến trình kéo các lớp (layers) của image và mã băm container ID được trả về trên màn hình Terminal.

Kiểm tra container đang chạy:

```bash
docker ps --filter "name=sonarqube" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```{{exec}}

---

### 2. Theo dõi tiến trình khởi động của SonarQube

SonarQube là ứng dụng Java lớn và khởi chạy Elasticsearch nội bộ, do đó thường mất khoảng 30 đến 45 giây để sẵn sàng nhận kết nối qua HTTP.

Hãy chạy lệnh vòng lặp kiểm tra API trạng thái hệ thống:

```bash
until curl -s http://localhost:9000/api/system/status 2>/dev/null | grep -q '"status":"UP"'; do
  echo "SonarQube dang khoi dong (Elasticsearch & Web Server)... Cho 5s"
  sleep 5
done
echo "SonarQube Server da san sang (UP)!"
```{{exec}}

Kiểm tra lại thông tin phiên bản và trạng thái trả về:

```bash
curl -s http://localhost:9000/api/system/status | jq .
```{{exec}}

Kết quả phản hồi chuẩn dạng JSON:
```json
{
  "id": "...",
  "version": "...",
  "status": "UP"
}
```

---

### 3. Đổi mật khẩu mặc định của tài khoản quản trị viên

Mặc định, tài khoản quản trị hệ thống là `admin` với mật khẩu ban đầu là `admin`. Để bảo mật và cho phép gọi API quản trị về sau mà không bị chặn, hãy cập nhật mật khẩu mới sang `AdminSecurePass123`:

```bash
curl -u admin:admin -X POST "http://localhost:9000/api/users/change_password?login=admin&previousPassword=admin&password=AdminSecurePass123"
```{{exec}}

Xác thực lại quyền truy cập với mật khẩu mới:

```bash
curl -u admin:AdminSecurePass123 -s "http://localhost:9000/api/authentication/validate" | jq .
```{{exec}}

Kết quả trả về `"valid": true` chứng minh tài khoản quản trị đã được thiết lập thành công.

Nhấn **Check** để hoàn thành bước 1!
