# Bước 2: Khởi Tạo Dự Án Mới & Sinh Token Xác Thực

Để quét mã nguồn, SonarQube yêu cầu dự án phải được định danh bằng một `projectKey` duy nhất. Thay vì dùng trực tiếp mật khẩu quản trị viên trong CI/CD, chúng ta sinh một **User Analysis Token** riêng biệt theo nguyên tắc Least Privilege.

---

### 1. Khởi tạo Dự Án trên SonarQube

Di chuyển vào thư mục dự án mẫu:

```bash
cd /root/sonarqube-lab && ls -la src/
```{{exec}}

Tạo dự án có `projectKey` là `express-api-service`:

```bash
curl -s -u admin:AdminSecurePass123 -X POST "http://localhost:9000/api/projects/create?name=Express+API+Service&project=express-api-service" | jq .
```{{exec}}

Nếu dự án đã tồn tại từ lần chạy trước, SonarQube trả về lỗi `already exists`. Bạn có thể bỏ qua và tiếp tục.

Kiểm tra dự án trên máy chủ:

```bash
curl -s -u admin:AdminSecurePass123 "http://localhost:9000/api/projects/search?projects=express-api-service" | jq .components
```{{exec}}

---

### 2. Sinh mã User Token cho CI/CD Scanner

Lệnh dưới đây thu hồi token cũ cùng tên nếu có, sinh token mới và lưu vào tệp `/root/sonarqube-lab/sonar-token.txt`:

```bash
curl -s -u admin:AdminSecurePass123 -X POST "http://localhost:9000/api/user_tokens/revoke?name=scanner-ci-token" > /dev/null; curl -s -u admin:AdminSecurePass123 -X POST "http://localhost:9000/api/user_tokens/generate?name=scanner-ci-token" | jq -r '.token' > /root/sonarqube-lab/sonar-token.txt; echo "Token: $(cat /root/sonarqube-lab/sonar-token.txt)"
```{{exec}}

Token hợp lệ của SonarQube 9.9 có dạng `squ_` theo sau là chuỗi ký tự dài. Nếu kết quả là `null`, hãy chạy lại lệnh trên.

Nhấn **Check** để hoàn thành bước 2.
