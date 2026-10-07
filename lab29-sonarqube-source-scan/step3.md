# Bước 3: Cấu Hình sonar-project.properties & Kích Hoạt SonarScanner

Trong dự án thực tế, cấu hình quét của SonarScanner được lưu trong tệp `sonar-project.properties` tại thư mục gốc repository để mọi lập trình viên và CI runner dùng chung.

---

### 1. Cài đặt SonarScanner CLI

SonarScanner CLI là công cụ dòng lệnh chính thức để quét và phân tích mã nguồn. Bản phân phối Linux đã đóng gói sẵn môi trường Java (OpenJDK 17) độc lập, giúp thực thi quét trực tiếp các ngôn ngữ như Python, Java, Secrets, Dockerfile mà không đòi hỏi cài đặt môi trường runtime bên ngoài.

Cài đặt SonarScanner CLI và tạo liên kết tượng trưng (symlink):

```bash
curl -fsSL https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip -o /tmp/sonar-scanner.zip && unzip -qo /tmp/sonar-scanner.zip -d /opt && ln -sf /opt/sonar-scanner-5.0.1.3006-linux/bin/sonar-scanner /usr/local/bin/sonar-scanner && sonar-scanner -v
```{{exec}}

---

### 2. Tạo tệp cấu hình sonar-project.properties

```bash
cd /root/sonarqube-lab
cat << 'EOF' > sonar-project.properties
# Dinh danh duy nhat cua du an tren SonarQube Server
sonar.projectKey=express-api-service

# Ten hien thi du an tren Dashboard
sonar.projectName=Express API Service
sonar.projectVersion=1.0.0

# Thu muc chua ma nguon can quet
sonar.sources=src

# Dinh dang ma hoa ky tu
sonar.sourceEncoding=UTF-8

# Dia chi may chu SonarQube
sonar.host.url=http://localhost:9000

# Bo qua cam bien SCM de toi uu toc do va bo nho RAM
sonar.scm.disabled=true
EOF
cat sonar-project.properties
```{{exec}}

---

### 3. Kích hoạt SonarScanner CLI

SonarScanner đọc cấu hình từ `sonar-project.properties`, tải bộ quy tắc phân tích từ server, quét mã nguồn trong `src/` và gửi báo cáo về Compute Engine.

Biến `SONAR_SCANNER_OPTS="-Xmx256m"` giới hạn bộ nhớ JVM của SonarScanner ở mức 256MB, giúp quá trình phân tích diễn ra nhẹ nhàng, mượt mà và hoàn thành chỉ trong vài giây:

```bash
cd /root/sonarqube-lab && SONAR_SCANNER_OPTS="-Xmx256m" sonar-scanner -Dsonar.login="$(cat sonar-token.txt)"
```{{exec}}

**Lưu ý quan trọng về SonarQube 9.9 LTS:**
* **Tham số token:** Sử dụng cờ `-Dsonar.login`. Tham số `-Dsonar.token` chỉ bắt đầu hỗ trợ từ bản 10.0. Nếu token gặp lỗi, có thể xác thực trực tiếp: `sonar-scanner -Dsonar.login=admin -Dsonar.password=AdminSecurePass123`

---

### 4. Kiểm tra kết quả thực thi

Các dòng cuối cùng trên Terminal:
```
INFO: Analysis report uploaded in ...ms
INFO: ANALYSIS SUCCESSFUL, you can find the results at: http://localhost:9000/dashboard?id=express-api-service
INFO: EXECUTION SUCCESS
```

SonarScanner sinh tệp `.scannerwork/report-task.txt` chứa mã tác vụ `ceTaskId` và đường dẫn báo cáo:

```bash
cat /root/sonarqube-lab/.scannerwork/report-task.txt
```{{exec}}

Nhấn **Check** để hoàn thành bước 3.
