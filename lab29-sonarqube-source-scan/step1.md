# Bước 1: Khởi Chạy SonarQube Server & Kiểm Tra Trạng Thái Sẵn Sàng

SonarQube Server bao gồm 3 thành phần chính chạy bên trong container: Web Server giao diện người dùng, công cụ tìm kiếm Elasticsearch và Compute Engine (CE) xử lý báo cáo phân tích mã nguồn.

Ở bước này, bạn sẽ tự cài công cụ hỗ trợ, khởi chạy container SonarQube Server và theo dõi tiến trình khởi động.

---

### 1. Cài đặt công cụ hỗ trợ

Cài `jq` để đọc phản hồi JSON và `unzip` để giải nén SonarScanner ở bước 3:

```bash
apt-get update -qq && apt-get install -y -qq jq unzip > /dev/null && echo "Da cai xong jq va unzip"
```{{exec}}

---

### 2. Khởi chạy Container SonarQube Server

Elasticsearch bên trong SonarQube yêu cầu tham số kernel `vm.max_map_count` tối thiểu là 262144:

```bash
sysctl -w vm.max_map_count=262144
```{{exec}}

Kéo image và chạy SonarQube Community Edition trên cổng `9000`. Quá trình tải image khoảng 600MB nên có thể mất 1 đến 2 phút:

```bash
docker run -d --name sonarqube -p 9000:9000 -e SONAR_SEARCH_JAVAADDITIONALOPTS="-Xmx256m -Xms256m" -e SONAR_WEB_JAVAADDITIONALOPTS="-Xmx256m -Xms256m" -e SONAR_CE_JAVAADDITIONALOPTS="-Xmx256m -Xms256m" -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true sonarqube:lts-community
```{{exec}}

Biến môi trường `SONAR_*_JAVAADDITIONALOPTS` giới hạn bộ nhớ RAM tối đa cho 3 tiến trình Java (Web, Compute Engine, Elasticsearch) ở mức 256MB mỗi tiến trình, giúp hệ thống hoạt động ổn định và không làm cạn kiệt RAM của máy chủ lab.

Kiểm tra container đang chạy:

```bash
docker ps --filter "name=sonarqube"
```{{exec}}

---

### 3. Theo dõi tiến trình khởi động của SonarQube

SonarQube là ứng dụng Java lớn và khởi chạy Elasticsearch nội bộ, thường mất 30 đến 90 giây sau khi container chạy để sẵn sàng nhận kết nối.

Chạy vòng lặp kiểm tra API trạng thái hệ thống:

```bash
until curl -s http://localhost:9000/api/system/status 2>/dev/null | grep -q '"status":"UP"'; do echo "SonarQube dang khoi dong... Cho 5s"; sleep 5; done; echo "SonarQube Server da san sang (UP)"
```{{exec}}

Nếu vòng lặp chạy quá 3 phút, xem log container để tìm nguyên nhân:

```bash
docker logs --tail 30 sonarqube
```{{exec}}

Kiểm tra lại thông tin phiên bản và trạng thái:

```bash
curl -s http://localhost:9000/api/system/status | jq .
```{{exec}}

Kết quả phản hồi:
```json
{
  "id": "...",
  "version": "9.9.x",
  "status": "UP"
}
```

---

### 4. Đổi mật khẩu mặc định của tài khoản quản trị viên

Tài khoản quản trị mặc định là `admin` với mật khẩu `admin`. Đổi sang mật khẩu mới `AdminSecurePass123`:

```bash
curl -s -u admin:admin -X POST "http://localhost:9000/api/users/change_password?login=admin&previousPassword=admin&password=AdminSecurePass123" && echo "Da doi mat khau"
```{{exec}}

Xác thực lại quyền truy cập với mật khẩu mới:

```bash
curl -s -u admin:AdminSecurePass123 "http://localhost:9000/api/authentication/validate" | jq .
```{{exec}}

Kết quả trả về `"valid": true` chứng minh tài khoản quản trị đã được thiết lập thành công.

Nhấn **Check** để hoàn thành bước 1.
