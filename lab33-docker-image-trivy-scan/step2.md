# Bước 2: Phân Tích Báo Cáo Layer & Quét Sai Sót Cấu Hình Dockerfile

Để bảo mật container hiệu quả, kỹ sư DevSecOps không chỉ nhìn vào số lượng CVE mà còn phải xác định chính xác nguồn gốc: Lỗ hổng đến từ Base Image của hệ điều hành, từ thư viện ứng dụng, hay từ cấu hình sai (Misconfiguration) trong Dockerfile.

---

### 1. Phân biệt hai nguồn lỗ hổng chính trong Container

Trong báo cáo JSON `initial-image-report.json` ở bước trước:
1. **OS Packages (Hệ điều hành cơ sở):** Các tệp nhị phân thuộc Alpine Linux như `busybox`, `libcrypto`, `ssl_client`. Lập trình viên ứng dụng không trực tiếp cài đặt các tệp này, chúng nằm sẵn trong Base Image `node:16-alpine`.
2. **Language Packages (Thư viện ứng dụng):** Các module Node.js được cài qua `npm install`.

Trích xuất nguồn phát hiện (Target) của các lỗ hổng:

```bash
cd /root/container-security-lab && jq -r '.Results[] | "Muc tieu: \(.Target) | Loai: \(.Class) | So lo hong: \(.Vulnerabilities | length)"' initial-image-report.json
```{{exec}}

Hầu hết các lỗ hổng Critical/High đều xuất phát từ hệ điều hành cơ sở của Alpine phiên bản cũ.

---

### 2. Truy vết các tầng Image Layers của Docker

Quan sát lịch sử các layer đã tạo nên image `payment-service:v1`:

```bash
docker history --human --format "table {{.CreatedBy}}\t{{.Size}}" payment-service:v1
```{{exec}}

Mỗi chỉ thị trong Dockerfile (`FROM`, `RUN`, `COPY`) tạo ra một layer bất biến (Immutable Layer). Nếu một layer bên dưới bị nhiễm lỗ hổng, mọi layer bên trên đều kế thừa mối nguy hiểm đó.

---

### 3. Quét sai sót cấu hình Dockerfile với Trivy Config

Ngoài quét mã nhị phân, Trivy hỗ trợ kiểm tra cấu hình mã hạ tầng (IaC / Dockerfile Misconfigurations) theo các tiêu chuẩn an ninh CIS Benchmark:

```bash
trivy config .
```{{exec}}

Trivy sẽ phát hiện các vi phạm cấu hình nghiêm trọng trong `Dockerfile`:
* **AVD-DS-0002 (Specify at least 1 USER command):** Không chỉ định người dùng, mặc định ứng dụng sẽ chạy với đặc quyền tối cao `root` (UID 0). Nếu ứng dụng bị chiếm quyền điều khiển (RCE), hacker có thể thoát khỏi container (Container Escape) và tấn công trực tiếp vào máy chủ Host.
* **Cài đặt tiện ích mạng thừa thãi:** Lệnh `apk add curl bash` cung cấp sẵn công cụ hỗ trợ cho tin tặc tải payload độc hại từ bên ngoài về máy chủ.

Xuất kết quả rà soát cấu hình Dockerfile ra tệp `dockerfile-misconfig.json`:

```bash
trivy config --format json -o dockerfile-misconfig.json .
```{{exec}}

Dùng `jq` trích xuất thông tin các cảnh báo cấu hình sai:

```bash
jq '[.Results[]?.Misconfigurations[]? | {ID: .ID, Title: .Title, Severity: .Severity, Message: .Message}]' dockerfile-misconfig.json
```{{exec}}

Nhấn **Check** để hoàn thành bước 2.
