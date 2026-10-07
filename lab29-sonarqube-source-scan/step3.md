# Bước 3: Cấu Hình sonar-project.properties & Kích Hoạt SonarScanner

Trong dự án thực tế, cấu hình quét của SonarScanner được lưu trong tệp `sonar-project.properties` tại thư mục gốc repository để mọi lập trình viên và CI runner dùng chung.

---

### 1. Cài đặt Node.js và SonarScanner CLI

Bộ phân tích JavaScript của SonarQube 9.9 cần **Node.js 14.17 trở lên** trên máy chạy scanner. Nếu thiếu Node.js, scanner sẽ báo lỗi khi phân tích tệp `.js`.

Cài Node.js 18 dạng binary:

```bash
curl -fsSL https://nodejs.org/dist/v18.20.4/node-v18.20.4-linux-x64.tar.gz | tar -xz -C /opt && ln -sf /opt/node-v18.20.4-linux-x64/bin/* /usr/local/bin/ && node -v
```{{exec}}

Cài SonarScanner CLI. Bản này đã đóng gói sẵn Java nên không cần cài JDK:

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

# Duong dan Node.js cho bo phan tich JavaScript/ESLint
sonar.nodejs.executable=/usr/local/bin/node
sonar.javascript.node.maxspace=512

# Bo qua cam bien SCM de toi uu toc do va bo nho RAM
sonar.scm.disabled=true
EOF
cat sonar-project.properties
```{{exec}}

---

### 3. Kích hoạt SonarScanner CLI

SonarScanner đọc cấu hình từ `sonar-project.properties`, tải bộ quy tắc từ server, phân tích mã nguồn trong `src/` và gửi báo cáo về Compute Engine.

Biến `SONAR_SCANNER_OPTS` cấu hình giới hạn RAM 256MB và ép dùng ngăn xếp IPv4 (`-Djava.net.preferIPv4Stack=true`) giúp kết nối nội bộ giữa Java và Node.js diễn ra mượt mà, tránh nghẽn loopback:

```bash
cd /root/sonarqube-lab && SONAR_SCANNER_OPTS="-Xmx256m -Djava.net.preferIPv4Stack=true" sonar-scanner -Dsonar.login="$(cat sonar-token.txt)"
```{{exec}}

**Lưu ý quan trọng về SonarQube 9.9 LTS:**

* **Tham số token:** Sử dụng cờ `-Dsonar.login`. Tham số `-Dsonar.token` chỉ bắt đầu hỗ trợ từ bản 10.0. Nếu token gặp lỗi, có thể xác thực trực tiếp: `sonar-scanner -Dsonar.login=admin -Dsonar.password=AdminSecurePass123`
* **Trường hợp gặp timeout 300s:** Nếu màn hình xuất hiện thông báo "Failed to start server (300s timeout)" nhưng các dòng cuối vẫn báo **ANALYSIS SUCCESSFUL** và **EXECUTION SUCCESS**: Quá trình quét vẫn **thành công 100%** và báo cáo đã được tải lên server đầy đủ. Bạn hoàn toàn có thể nhấn **Check** để sang bước tiếp theo.

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
