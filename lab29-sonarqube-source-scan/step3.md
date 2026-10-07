# Bước 3: Cấu Hình sonar-project.properties & Kích Hoạt SonarScanner

Trong các dự án phần mềm chuyên nghiệp, cấu hình quét mã nguồn của SonarScanner được lưu trữ tập trung trong tệp `sonar-project.properties` tại thư mục gốc của repository. Điều này giúp các lập trình viên và CI runner dễ dàng tái sử dụng cùng một bộ quy tắc.

---

### 1. Cài đặt SonarScanner CLI

Kiểm tra và cài đặt công cụ dòng lệnh SonarScanner CLI:

```bash
if ! command -v sonar-scanner > /dev/null 2>&1; then
  echo "Dang cai dat SonarScanner CLI..."
  curl -fsSL https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip -o /tmp/sonar-scanner.zip
  unzip -q /tmp/sonar-scanner.zip -d /opt
  rm -f /tmp/sonar-scanner.zip
  ln -sf /opt/sonar-scanner-*/bin/sonar-scanner /usr/local/bin/sonar-scanner
fi
sonar-scanner -v
```{{exec}}

---

### 2. Tạo tệp cấu hình sonar-project.properties

Di chuyển vào thư mục `/root/sonarqube-lab` và khởi tạo tệp cấu hình:

```bash
cd /root/sonarqube-lab

cat << 'EOF' > sonar-project.properties
# Dinh danh duy nhat cua du an tren SonarQube Server
sonar.projectKey=express-api-service

# Ten hien thi du an tren Dashboard
sonar.projectName=Express API Service
sonar.projectVersion=1.0.0

# Duong dan thu muc chua ma nguon can quet
sonar.sources=src

# Dinh dang ma hoa ky tu
sonar.sourceEncoding=UTF-8

# Dia chi may chu SonarQube
sonar.host.url=http://localhost:9000
EOF
```{{exec}}

Xem lại nội dung cấu hình:

```bash
cat sonar-project.properties
```{{exec}}

---

### 3. Kích hoạt SonarScanner CLI

SonarScanner CLI đọc cấu hình từ `sonar-project.properties`, nạp các Ruleset từ SonarQube Server tương ứng với ngôn ngữ JavaScript, phân tích cây cú pháp trừu tượng (AST) của các tệp mã nguồn trong thư mục `src/`, và đóng gói báo cáo gửi về Compute Engine.

Thực hiện lệnh quét với Token xác thực:

```bash
SONAR_TOKEN=$(cat /root/sonarqube-lab/sonar-token.txt)
sonar-scanner -Dsonar.login="$SONAR_TOKEN"
```{{exec}}

> **Lưu ý quan trọng về phiên bản SonarQube 9.9 LTS:**
> * Đối với máy chủ SonarQube LTS (phiên bản 9.9), tham số nạp User Token trên SonarScanner CLI là `-Dsonar.login="$SONAR_TOKEN"` (tham số `-Dsonar.token` chỉ bắt đầu hỗ trợ từ SonarQube 10.0+).
> * Bạn cũng có thể xác thực trực tiếp bằng tài khoản quản trị:
>   `sonar-scanner -Dsonar.login=admin -Dsonar.password=AdminSecurePass123`

---

### 4. Kiểm tra kết quả thực thi của Scanner

Quan sát các dòng nhật ký cuối cùng trên màn hình Terminal:
```
INFO: Analysis report generated in 50ms, dirSize=...
INFO: Analysis report compressed in 20ms, zipSize=...
INFO: Analysis report uploaded in ...ms
INFO: ANALYSIS SUCCESSFUL, you can find the results at: http://localhost:9000/dashboard?id=express-api-service
INFO: Note that you will be able to access the updated dashboard once the server has finished processing the submitted analysis report
INFO: EXECUTION SUCCESS
```

Sau khi quá trình quét thành công, SonarScanner sẽ sinh thư mục lưu trữ thông tin tạm thời `.scannerwork/report-task.txt`. Kiểm tra tệp thông số tác vụ:

```bash
cat .scannerwork/report-task.txt
```{{exec}}

Tệp này ghi nhận thông tin `ceTaskId` và đường dẫn xem báo cáo phân tích trực tiếp.

Nhấn **Check** để hoàn thành bước 3!
