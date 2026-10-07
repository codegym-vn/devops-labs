# Lab 29: Cấu Hình SonarQube Quét Mã Nguồn & Phân Tích Chất Lượng

Trong quy trình phát triển phần mềm hiện đại và DevSecOps, việc kiểm thử an ninh tĩnh (SAST - Static Application Security Testing) và quản lý nợ kỹ thuật (Technical Debt) là yếu tố sống còn trước khi đưa mã nguồn lên môi trường Production.

**SonarQube** là nền tảng phân tích mã nguồn mở và thương mại hàng đầu thế giới, giúp phát hiện tự động:
* **Vulnerabilities (Lỗ hổng bảo mật):** Nguy cơ SQL Injection, XSS, rò rỉ dữ liệu nhạy cảm.
* **Bugs (Lỗi logic):** Null pointer, vòng lặp vô hạn, rò rỉ bộ nhớ.
* **Security Hotspots:** Các đoạn mã nhạy cảm cần chuyên gia bảo mật rà soát thủ công.
* **Code Smells & Maintainability:** Mã nguồn khó đọc, trùng lặp code (Duplication), biến không sử dụng.

---

## 1. Kiến Trúc Hoạt Động Của SonarQube Trong CI/CD

```
┌────────────────────────┐      Đẩy mã nguồn      ┌────────────────────────┐
│  Developer / CI Runner ├───────────────────────►│    SonarQube Server    │
│                        │                        │                        │
│ ┌────────────────────┐ │  sonar-project.prop    │  - Web UI (Port 9000)  │
│ │   SonarScanner     │ │                        │  - Search Engine (ES)  │
│ │        CLI         │ │  POST /api/ce/submit   │  - Compute Engine (CE) │
│ └────────────────────┘ │───────────────────────►│  - Database (Postgres) │
└────────────────────────┘                        └───────────┬────────────┘
                                                              │
                                                              ▼
                                                   [Quality Gate Decision]
                                                   - PASSED: Cho phép merge
                                                   - FAILED: Chặn pipeline
```

* **SonarQube Server:** Chịu trách nhiệm nhận báo cáo phân tích, lưu trữ dữ liệu chỉ số, cung cấp giao diện Web Dashboard và đánh giá Cổng chất lượng (Quality Gate).
* **SonarScanner:** Công cụ dòng lệnh (CLI) chạy trực tiếp tại máy phát triển hoặc CI Runner, quét cây thư mục mã nguồn và gửi dữ liệu nén về máy chủ SonarQube.

---

## 2. Mục Tiêu Bạn Cần Đạt Được Trong Bài Lab Này

1. Kiểm tra và giám sát trạng thái khởi động của **SonarQube Community Server** trên container Docker (Port 9000).
2. Khởi tạo dự án mới và tạo mã xác thực bảo mật (**User Token**) để cấp quyền cho scanner.
3. Thiết lập tệp cấu hình chuẩn hóa `sonar-project.properties` và thực thi **SonarScanner CLI**.
4. Khám phá bảng điều khiển báo cáo phân tích, kiểm tra chỉ số nợ kỹ thuật và xác nhận trạng thái **Quality Gate** qua REST API.

Nhấn **Next** để bắt đầu bước đầu tiên!
