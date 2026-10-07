# Bước 1: Khởi Chạy SonarQube Server & Kiểm Tra Trạng Thái Sẵn Sàng

SonarQube Server bao gồm 3 thành phần chính chạy bên trong container: Web Server giao diện người dùng, công cụ tìm kiếm Elasticsearch và Compute Engine (CE) xử lý báo cáo phân tích mã nguồn.

Hệ thống đã tự động kích hoạt container `sonarqube` trên cổng `9000`. Hãy kiểm tra trạng thái khởi động của máy chủ.

---

### 1. Kiểm tra trạng thái Container SonarQube

Kiểm tra container đang chạy:

```bash
docker ps --filter "name=sonarqube" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```{{exec}}

---

### 2. Theo dõi tiến trình khởi động của SonarQube

SonarQube là ứng dụng Java lớn và khởi chạy Elasticsearch nội bộ, do đó thường mất khoảng 30 đến 45 giây để sẵn sàng nhận kết nối.

Hãy chạy lệnh vòng lặp kiểm tra API trạng thái hệ thống:

```bash
until curl -s http://localhost:9000/api/system/status | grep -q '"status":"UP"'; do
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
