# Bước 2: Khởi Tạo Dự Án Mới & Sinh Token Xác Thực

Để quét một mã nguồn, SonarQube yêu cầu mã nguồn phải được định danh bằng một `projectKey` duy nhất. Ngoài ra, thay vì sử dụng trực tiếp mật khẩu quản trị viên trong các tiến trình CI/CD, chúng ta cần sinh một **User Analysis Token** riêng biệt nhằm tuân thủ nguyên tắc bảo mật Least Privilege.

---

### 1. Khởi tạo Dự Án (Project) trên SonarQube

Di chuyển vào thư mục dự án mẫu:

```bash
cd /root/sonarqube-lab
```

Thực hiện tạo dự án có `projectKey` là `express-api-service` và tên hiển thị là `Express API Service`:

```bash
curl -u admin:AdminSecurePass123 -s -X POST "http://localhost:9000/api/projects/create?name=Express+API+Service&project=express-api-service" | jq .
```

Kiểm tra danh sách dự án hiện có trên máy chủ:

```bash
curl -u admin:AdminSecurePass123 -s "http://localhost:9000/api/projects/search?projects=express-api-service" | jq .components
```

Dự án đã được lưu trữ trong cơ sở dữ liệu của SonarQube.

---

### 2. Sinh mã User Token cho CI/CD Scanner

Mã Analysis Token cho phép công cụ `sonar-scanner` xác thực an toàn với máy chủ mà không làm lộ mật khẩu của quản trị viên.

Tạo token mới có tên `scanner-ci-token`:

```bash
TOKEN_RESPONSE=$(curl -u admin:AdminSecurePass123 -s -X POST "http://localhost:9000/api/user_tokens/generate?name=scanner-ci-token")
echo "$TOKEN_RESPONSE" | jq .
```

Trích xuất giá trị token và lưu vào tệp `/root/sonarqube-lab/sonar-token.txt`:

```bash
SONAR_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.token')
echo "$SONAR_TOKEN" > /root/sonarqube-lab/sonar-token.txt
echo "Da luu Token: $SONAR_TOKEN"
```

Kiểm tra lại token đã được ghi nhận:

```bash
cat /root/sonarqube-lab/sonar-token.txt
```

Nhấn **Check** để hoàn thành bước 2!
