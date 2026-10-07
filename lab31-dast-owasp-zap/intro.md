# Lab 31: Tích Hợp OWASP ZAP Quét Ứng Dụng Đang Chạy (DAST)

Trong khi phương pháp kiểm thử tĩnh (SAST) quét trực tiếp các dòng mã nguồn (White-box testing), thì **Dynamic Application Security Testing (DAST)** đóng vai trò kiểm thử hộp đen (Black-box testing) từ bên ngoài. DAST tương tác trực tiếp với ứng dụng khi nó đang thực thi (Runtime), mô phỏng các hành vi tấn công thực tế của tin tặc qua giao thức mạng HTTP/HTTPS.

**OWASP Zed Attack Proxy (ZAP)** là công cụ quét an ninh ứng dụng web mã nguồn mở phổ biến nhất thế giới do tổ chức OWASP phát triển và duy trì.

---

## 1. So Sánh Cơ Chế SAST và DAST Trong DevSecOps

```
┌─────────────────────────────────┐           ┌─────────────────────────────────┐
│              SAST               │           │              DAST               │
│ (Static Application Sec Testing)│           │(Dynamic Application Sec Testing)│
├─────────────────────────────────┤           ├─────────────────────────────────┤
│ • Tiếp cận: White-box           │           │ • Tiếp cận: Black-box           │
│ • Quét: File mã nguồn tĩnh      │           │ • Quét: HTTP Endpoint đang chạy │
│ • Giai đoạn: Commit / Code PR   │           │ • Giai đoạn: Staging / Pre-prod │
│ • Lợi thế: Chỉ rõ dòng code sai │           │ • Lợi thế: Không phụ thuộc lang │
│ • Điểm yếu: Hay bị False Pos    │           │ • Kiểm tra: Header, Cookie, TLS │
└─────────────────────────────────┘           └─────────────────────────────────┘
```

---

## 2. Mục Tiêu Bạn Cần Đạt Được Trong Bài Lab Này

1. Khởi chạy ứng dụng Web mục tiêu trên cổng `3000` và khảo sát bề mặt tấn công thông qua phân tích tiêu đề HTTP (Response Headers).
2. Tích hợp và thực thi công cụ **OWASP ZAP Baseline Scan** quét thụ động (Passive Scanning) ứng dụng đang chạy.
3. Phân tích chi tiết báo cáo rủi ro DAST: Lỗ hổng Clickjacking (Missing X-Frame-Options), Content Security Policy (CSP), MIME Sniffing, và rò rỉ phiên bản máy chủ (`X-Powered-By`).
4. Khắc phục triệt để toàn bộ cảnh báo an ninh bằng cách tích hợp thư viện **Helmet.js** middleware và kiểm thử nghiệm thu bảo mật.

Nhấn **Next** để bắt đầu bước đầu tiên!
