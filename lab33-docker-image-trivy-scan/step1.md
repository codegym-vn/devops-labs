# Bước 1: Khởi Tạo Image Mục Tiêu & Quét Lỗ Hổng Container Ban Đầu

Trong bước này, bạn sẽ cài đặt công cụ phân tích an ninh container **Trivy**, đóng gói Docker Image đầu tiên cho dịch vụ `payment-service` và thực thi quét lỗ hổng ban đầu để phát hiện các mối nguy hiểm bảo mật tiềm ẩn.

---

### 1. Cài đặt công cụ Trivy và jq

Cài đặt Trivy CLI dạng binary chính thức vào thư mục `/usr/local/bin`:

```bash
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin && chmod +x /usr/local/bin/trivy && trivy --version
```{{exec}}

Cài đặt công cụ xử lý JSON `jq`:

```bash
apt-get update -qq && apt-get install -y -qq jq > /dev/null && echo "Da cai xong jq"
```{{exec}}

---

### 2. Khảo sát mã nguồn và Dockerfile ban đầu

Di chuyển vào thư mục dự án và kiểm tra các tệp cấu hình:

```bash
cd /root/container-security-lab && ls -la && cat Dockerfile
```{{exec}}

Dockerfile ban đầu có một số điểm yếu phổ biến:
* Sử dụng Base Image `node:16-alpine` (phiên bản Alpine cũ đã hết hạn hỗ trợ chính thức, chứa nhiều lỗ hổng trong các gói hệ thống).
* Cài đặt thêm các gói công cụ không cần thiết (`curl`, `bash`) làm gia tăng bề mặt tấn công.
* Không cấu hình chỉ thị `USER` (mặc định container chạy dưới quyền `root`, tiềm ẩn nguy cơ Container Breakout).

---

### 3. Đóng gói Docker Image phiên bản v1

Xây dựng Docker Image với tag `payment-service:v1`:

```bash
cd /root/container-security-lab && docker build -t payment-service:v1 .
```{{exec}}

Kiểm tra kích thước image vừa được tạo:

```bash
docker images payment-service:v1
```{{exec}}

---

### 4. Thực thi quét an ninh với Trivy Image

Trivy tự động bóc tách từng lớp (Layers) của container image, phân tích danh sách các gói nhị phân của hệ điều hành và các thư viện ngôn ngữ:

```bash
trivy image --severity HIGH,CRITICAL payment-service:v1
```{{exec}}

Bảng kết quả quét trả về:
* **Target**: Vị trí phát hiện lỗ hổng (ví dụ: `Node.js (node:16-alpine 3.16.9)` hoặc `node-pkg (package-lock.json)`).
* **Package**: Tên thư viện hệ điều hành (ví dụ: `ssl_client`, `busybox`, `zlib`, `openssl`).
* **Vulnerability ID**: Mã định danh CVE quốc tế.
* **Severity**: Mức độ nghiêm trọng theo thang điểm chuẩn CVSS (HIGH, CRITICAL).
* **Installed Version & Fixed Version**: Phiên bản hiện tại và phiên bản tối thiểu đã có bản vá từ nhà phân phối OS.

---

### 5. Xuất báo cáo quét ra định dạng JSON

Xuất toàn bộ kết quả quét ra tệp `initial-image-report.json`:

```bash
trivy image --format json -o initial-image-report.json payment-service:v1
```{{exec}}

Sử dụng `jq` thống kê số lượng lỗ hổng mức độ HIGH và CRITICAL:

```bash
jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH" or .Severity == "CRITICAL")] | length' initial-image-report.json
```{{exec}}

Trích xuất danh sách 5 lỗ hổng nghiêm trọng tiêu biểu kèm gói hệ điều hành bị ảnh hưởng:

```bash
jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH" or .Severity == "CRITICAL") | {Package: .PkgName, Version: .InstalledVersion, FixedIn: .FixedVersion, Severity: .Severity, CVE: .VulnerabilityID}] | .[0:5]' initial-image-report.json
```{{exec}}

Nhấn **Check** để hoàn thành bước 1.
