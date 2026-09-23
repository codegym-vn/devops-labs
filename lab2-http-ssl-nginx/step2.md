# Bước 2: HTTPS & Bắt Tay TLS - Kiểm Tra Certificate Thực Tế

Trong bước trước, bạn đã thấy HTTP truyền dữ liệu hoàn toàn dưới dạng **plaintext** — bất kỳ ai nằm giữa đường truyền (man-in-the-middle) đều có thể đọc, sửa đổi nội dung. **HTTPS** giải quyết vấn đề này bằng cách bọc một lớp mã hóa **TLS (Transport Layer Security)** quanh giao thức HTTP.

---

## 1. Ba Mục Tiêu Bảo Mật Của HTTPS

| Mục Tiêu | Giải Thích | Hậu Quả Nếu Thiếu |
|---|---|---|
| **Mã hóa (Encryption)** | Dữ liệu được mã hóa trên đường truyền, chỉ client và server đọc được | Hacker đọc được password, API key, dữ liệu nhạy cảm |
| **Xác thực (Authentication)** | Server xuất trình Certificate để chứng minh danh tính | Client có thể kết nối nhầm vào server giả mạo (phishing) |
| **Toàn vẹn (Integrity)** | Mọi thay đổi dữ liệu trên đường truyền đều bị phát hiện | Dữ liệu bị chèn thêm mã độc hoặc quảng cáo giữa đường |

---

## 2. Quy Trình Bắt Tay TLS (TLS Handshake)

Trước khi truyền bất kỳ dữ liệu HTTP nào qua HTTPS, client và server phải thực hiện **bắt tay TLS** để thỏa thuận khóa mã hóa:

```text
  Client                                    Server
    |                                         |
    | --- 1. ClientHello ------------------> |  Gửi: TLS version, danh sách Cipher Suites
    |                                         |
    | <-- 2. ServerHello ------------------- |  Chọn: Cipher Suite, gửi Certificate
    |                                         |
    | --- 3. Xác minh Certificate ---------> |  Client kiểm tra: CA hợp lệ? Hết hạn chưa? Domain khớp?
    |                                         |
    | --- 4. Key Exchange (Pre-Master) ----> |  Trao đổi khóa bí mật để tạo Session Key
    |                                         |
    | <-- 5. Finished ---------------------- |  Cả hai phía xác nhận sẵn sàng
    |                                         |
    | === Dữ liệu HTTP được mã hóa ======== |  GET /api/data HTTP/1.1 (encrypted)
```

> **Lưu ý:** TLS Handshake diễn ra **sau** TCP 3-Way Handshake (đã học ở Lab 1, Bước 2) và **trước** khi bất kỳ dữ liệu HTTP nào được gửi.

---

## 3. Chuỗi Chứng Chỉ (Certificate Chain)

Một Certificate không đứng độc lập — nó được xác thực theo chuỗi tin tưởng (Chain of Trust):

```text
[Root CA Certificate]              Ví dụ: DigiCert Global Root G2
        |                          (Được cài sẵn trong OS/Browser)
        v
[Intermediate CA Certificate]      Ví dụ: DigiCert SHA2 Extended Validation Server CA
        |                          (Cầu nối giữa Root và Leaf)
        v
[Leaf Certificate (Server)]        Ví dụ: CN=www.google.com
                                   (Certificate của website/server)
```

- **Root CA**: Được OS và trình duyệt tin tưởng sẵn (pre-installed). Toàn thế giới chỉ có khoảng 150 Root CA.
- **Intermediate CA**: Tăng bảo mật bằng cách không dùng Root CA trực tiếp để ký.
- **Leaf Certificate**: Certificate của website/domain của bạn.

---

## 4. Thực Hành: Kiểm Tra Certificate Với `openssl s_client`

Công cụ `openssl s_client` cho phép bạn kết nối TLS trực tiếp tới server và xem toàn bộ thông tin certificate.

### Kết nối và kiểm tra certificate của Google

```bash
echo | openssl s_client -connect google.com:443 -servername google.com 2>/dev/null | openssl x509 -noout -subject -issuer -dates
```{{exec}}

Giải thích các trường:
- **subject**: Chủ thể sở hữu certificate (tên miền hoặc tổ chức).
- **issuer**: Tổ chức cấp phát (Certificate Authority).
- **notBefore / notAfter**: Thời gian hiệu lực của certificate.

### Xem toàn bộ chuỗi certificate chain

```bash
echo | openssl s_client -connect google.com:443 -servername google.com -showcerts 2>/dev/null | grep -E "s:|i:" | head -10
```{{exec}}

Quan sát:
- `s:` (subject) — Chủ thể của từng certificate trong chuỗi.
- `i:` (issuer) — Tổ chức đã ký (cấp phát) certificate đó.
- Thứ tự: Leaf -> Intermediate -> Root.

### Kiểm tra certificate của một domain khác

Thử với GitHub:

```bash
echo | openssl s_client -connect github.com:443 -servername github.com 2>/dev/null | openssl x509 -noout -subject -issuer -dates
```{{exec}}

### Kiểm tra ngày hết hạn cụ thể

Trong DevOps, kiểm tra ngày hết hạn certificate là tác vụ monitoring quan trọng để tránh sự cố mất HTTPS giữa đêm:

```bash
echo | openssl s_client -connect google.com:443 -servername google.com 2>/dev/null | openssl x509 -noout -enddate
```{{exec}}

---

## 5. Phân Biệt Các Loại Certificate

| Loại | Mục Đích | Giá | Sử Dụng |
|---|---|---|---|
| **Self-Signed** | Tự ký, không có CA xác thực | Miễn phí | Dev/Test, môi trường nội bộ |
| **Domain Validated (DV)** | CA xác minh quyền sở hữu domain | Miễn phí (Let's Encrypt) | Website, API nhỏ |
| **Organization Validated (OV)** | CA xác minh tổ chức | Trả phí | Doanh nghiệp, API nội bộ |
| **Extended Validation (EV)** | Xác minh pháp lý nghiêm ngặt | Trả phí cao | Ngân hàng, tài chính |
| **Wildcard** | Bao phủ tất cả subdomain (`*.example.com`) | Trả phí | Nhiều subdomain cùng domain chính |

> **Trong thực tế DevOps:** Phần lớn hệ thống sử dụng **Let's Encrypt (DV)** cho production và **Self-Signed** cho môi trường staging/dev. Bước 3 sẽ hướng dẫn tạo Self-Signed Certificate.

---

## 6. Quan Sát HTTPS Qua `curl -v`

So sánh với HTTP ở Bước 1, hãy xem thêm phần TLS handshake khi kết nối HTTPS:

```bash
curl -v -s -o /dev/null https://example.com 2>&1 | head -25
```{{exec}}

Chú ý các dòng mới xuất hiện so với HTTP:
- `* TLSv1.3 (OUT), TLS handshake, Client hello` — Bắt đầu bắt tay TLS.
- `* SSL connection using TLSv1.3 / ...` — Phiên bản TLS và cipher suite đã thỏa thuận.
- `* Server certificate:` — Thông tin certificate của server.
- `* subject:` và `* issuer:` — Chủ thể và tổ chức cấp phát.

---

## 7. Thử Thách & Xác Thực (Verification)

Hãy sử dụng `openssl s_client` để kiểm tra certificate của domain `github.com` trên cổng `443`.

1. Trích xuất dòng **subject** của certificate (dòng chứa `subject=...`).
2. Khi đã xác định được thông tin, hãy **tự tay gõ lệnh** trên terminal để lưu tên tổ chức (Organization) từ trường subject vào file:
   ```bash
   echo "<TEN_TO_CHUC>" > /tmp/cert_subject.txt
   ```
   *(Ví dụ: nếu subject chứa `O = GitHub, Inc.`, hãy gõ `echo "GitHub, Inc." > /tmp/cert_subject.txt`)*

3. Bấm nút **Check** bên dưới thanh điều khiển để hệ thống xác thực kết quả!
