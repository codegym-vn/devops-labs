# Bước 1: Khởi Tạo OCI Registry, Cài Đặt Cosign & Tạo Cặp Khóa

Trong bước này, bạn sẽ khởi chạy một kho lưu trữ Docker Registry cục bộ để lưu trữ image và chữ ký số, cài đặt công cụ **Cosign CLI**, và tạo lập cặp khóa mật mã bất đối xứng phục vụ cho việc ký và xác thực.

---

### 1. Khởi chạy OCI Registry cục bộ

Trong môi trường thực tế, doanh nghiệp sử dụng các Registry như Harbor, Docker Hub, AWS ECR, hay Google Artifact Registry. Để thực hành trọn vẹn quy trình đẩy và lưu trữ chữ ký số OCI, chúng ta khởi chạy một Registry cục bộ trên cổng `5000`:

```bash
docker run -d -p 5000:5000 --restart=always --name registry registry:2
```{{exec}}

Kiểm tra trạng thái hoạt động của Registry qua API:

```bash
curl -s http://localhost:5000/v2/_catalog
```{{exec}}

Kết quả `{"repositories":[]}` xác nhận Registry đã sẵn sàng tiếp nhận image.

---

### 2. Cài đặt Cosign CLI và jq

Tải bản phân phối nhị phân chính thức của **Cosign** (Sigstore) vào `/usr/local/bin`:

```bash
curl -fsSL https://github.com/sigstore/cosign/releases/download/v2.2.4/cosign-linux-amd64 -o /usr/local/bin/cosign && chmod +x /usr/local/bin/cosign && cosign version
```{{exec}}

Cài đặt công cụ xử lý JSON `jq`:

```bash
apt-get update -qq && apt-get install -y -qq jq > /dev/null && echo "Da cai xong jq"
```{{exec}}

---

### 3. Tạo cặp khóa mật mã bất đối xứng (Key Pair)

Cosign hỗ trợ ký số bằng cặp khóa công khai / khóa bí mật (ECDSA-P256):
* **Private Key (cosign.key):** Dùng để ký số lên image trong quá trình build CI/CD. Khóa này phải được bảo vệ tuyệt mật (lưu trong HashiCorp Vault, GitHub Secrets hoặc KMS).
* **Public Key (cosign.pub):** Dùng để xác thực tính toàn vẹn của image tại thời điểm triển khai trên Kubernetes hoặc máy chủ Production.

Thiết lập biến môi trường `COSIGN_PASSWORD` để tự động hóa quá trình sinh khóa mà không bị gián đoạn bởi prompt tương tác:

```bash
cd /root/cosign-signing-lab && COSIGN_PASSWORD="SecureCosignPass123" cosign generate-key-pair
```{{exec}}

Kiểm tra hai tệp khóa vừa được khởi tạo:

```bash
ls -lh cosign.key cosign.pub
```{{exec}}

Xem nội dung khóa công khai:

```bash
cat cosign.pub
```{{exec}}

Khóa công khai có định dạng PEM tiêu chuẩn với tiêu đề `BEGIN PUBLIC KEY`, sẵn sàng phân phối cho các máy chủ xác thực.

Nhấn **Check** để hoàn thành bước 1.
