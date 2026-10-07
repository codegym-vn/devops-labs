# Lab 33: Quét Docker Image Với Trivy (Container Security)

Container đã trở thành đơn vị đóng gói và phân phối phần mềm tiêu chuẩn trong kỷ nguyên Cloud Native và DevOps. Tuy nhiên, việc một ứng dụng an toàn ở tầng mã nguồn (SAST) và tầng phụ thuộc (SCA) vẫn chưa đủ để bảo đảm an toàn khi vận hành trong môi trường Production.

Một Docker Image chứa đựng cả một hệ điều hành thu nhỏ (Base OS), các thư viện hệ thống (OpenSSL, glibc, musl, curl, tar) và các tệp cấu hình runtime. Hơn **85% lỗ hổng bảo mật trong container** thực chất xuất phát từ chính hệ điều hành cơ sở (Base Image) chứ không nằm trong mã nguồn của ứng dụng.

---

## 1. Kiến Trúc Kiểm Thử An Ninh Container Của Trivy

```
┌────────────────────────────────────────────────────────────────────────┐
│                        TRIVY CONTAINER SCANNER                         │
├───────────────────────────────────┬────────────────────────────────────┤
│         OS PACKAGES (HỆ ĐIỀU HÀNH)│    APPLICATION RUNTIME (NGÔN NGỮ)  │
├───────────────────────────────────┼────────────────────────────────────┤
│ • Alpine: apk, musl, busybox, ssl │ • Node.js: package-lock.json       │
│ • Debian/Ubuntu: apt, glibc, zlib │ • Python: requirements.txt, pip    │
│ • RedHat/CentOS: rpm, openssl     │ • Java: pom.xml, jar, gradle       │
├───────────────────────────────────┴────────────────────────────────────┤
│                  CONTAINER MISCONFIGURATIONS (DOCKERFILE)              │
├────────────────────────────────────────────────────────────────────────┤
│ • Chạy dưới quyền root (UID 0)    │ • Lộ Secret / API Key trong Layer  │
│ • Quyền ghi vào thư mục gốc       │ • Cài đặt thừa tiện ích tấn công   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Mục Tiêu Bạn Cần Đạt Được Trong Bài Lab Này

1. **Khởi tạo và đóng gói Container Image mẫu:** Xây dựng ứng dụng thanh toán mẫu `payment-service:v1` trên Base Image chưa được vá lỗi bảo mật.
2. **Thực thi quét Container với Trivy:** Bóc tách các lớp Layer để phát hiện các lỗ hổng nhân hệ điều hành (OS Packages) và lỗ hổng thư viện runtime (Language Packages).
3. **Phân tích sai sót cấu hình (Misconfigurations):** Sử dụng `trivy config` để tìm ra các lỗi thiết kế bảo mật trong Dockerfile.
4. **Tối ưu hóa Dockerfile Multi-stage:** Tái cấu trúc Dockerfile theo chuẩn Multi-stage Build, nâng cấp Base Image tối giản, thiết lập Non-root user và quản lý ngoại lệ bảo mật với `.trivyignore`.
5. **Thiết lập Container Security Gate & Xuất SBOM:** Xây dựng script kiểm tra an ninh tự động chặn phát hành image có CVE nguy hiểm và xuất danh mục linh kiện phần mềm SBOM chuẩn CycloneDX.

Nhấn **Next** để bắt đầu bước đầu tiên!
