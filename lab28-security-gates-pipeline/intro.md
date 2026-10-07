# Lab 28: Xây Dựng Security Gates Trong CI/CD Pipeline

Trong mô hình DevOps truyền thống, quy trình CI/CD thường chỉ tập trung vào việc: Biên dịch mã nguồn (Build), chạy Unit Test, đóng gói Docker Image và triển khai (Deploy). Nếu các lỗ hổng bảo mật hoặc khóa bí mật lọt vào mã nguồn, chúng sẽ được tự động đóng gói và đẩy thẳng lên môi trường Production.

Để chuyển đổi sang **DevSecOps**, chúng ta thiết lập các **Security Gates (Cổng kiểm soát an ninh tự động)** tại từng giai đoạn của pipeline:

---

## 1. Kiến Trúc Security Gates Đa Tầng

```
    MÃ NGUỒN MỚI
         │
         ▼
┌─────────────────────────────────┐
│     GATE 1: SECRET SCANNING     │ ──► [Phát hiện API Key / Token lộ?] ──► FAIL & BLOCK!
│           (Gitleaks)            │
└────────────────┬────────────────┘
                 │ (Pass)
                 ▼
┌─────────────────────────────────┐
│       GATE 2: SCA & SAST        │ ──► [Dependencies có mã CVE nguy cấp?] ──► FAIL & BLOCK!
│         (Trivy Repo/Fs)         │
└────────────────┬────────────────┘
                 │ (Pass)
                 ▼
┌─────────────────────────────────┐
│     GATE 3: CONTAINER SCAN      │ ──► [Base Image Linux có CVE Critical?] ──► FAIL & BLOCK!
│          (Trivy Image)          │
└────────────────┬────────────────┘
                 │ (Pass)
                 ▼
┌─────────────────────────────────┐
│        DEPLOY PRODUCTION        │
└─────────────────────────────────┘
```

* **Nguyên tắc "Fail-Fast":** Nếu Gate 1 phát hiện lộ secret, pipeline lập tức dừng lại, không tốn tài nguyên build Docker hay chạy test.
* **Ngưỡng chặn nghiêm ngặt (Strict Threshold):** Chỉ cho phép vượt qua nếu các chỉ số lỗ hổng ở mức `CRITICAL` và `HIGH` bằng 0.

---

## 2. Mục Tiêu Bạn Cần Đạt Được Trong Bài Lab Này

* Thiết lập Gate 1: Quét rò rỉ secret bằng `Gitleaks` với ngưỡng chặn ngay lập tức.
* Thiết lập Gate 2: Quét phân tích thành phần phần mềm (SCA) cho thư viện phụ thuộc bằng `Trivy fs`.
* Thiết lập Gate 3: Quét lỗ hổng hệ điều hành và gói phần mềm trong Docker Image bằng `Trivy image`.
* Xây dựng workflow hoàn chỉnh trên GitHub Actions kết hợp cả 3 Gate và kiểm thử cơ chế chặn phát hành khi có lỗi giả lập.

Nhấn **Next** để bắt đầu bước đầu tiên!
