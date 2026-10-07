# Lab 24: Thực Hành Triển Khai Ứng Dụng Tự Động Lên Cụm Kubernetes Theo Chiến Lược Canary Deployment

Trong quy trình phát triển và vận hành phần mềm hiện đại, việc cập nhật phiên bản mới trực tiếp lên toàn bộ môi trường Production (Recreate hoặc Big Bang) tiềm ẩn rủi ro rất lớn. Một lỗi tiềm ẩn chưa được phát hiện trong quá trình kiểm thử có thể làm tê liệt toàn bộ hệ thống và ảnh hưởng đến 100% người dùng.

Để giải quyết triệt để rủi ro này, chiến lược **Canary Deployment** ra đời. Tên gọi này bắt nguồn từ truyền thống của những người thợ mỏ mang chim hoàng yến (canary) vào hầm mỏ: nếu có khí độc rò rỉ, chim hoàng yến sẽ bị ảnh hưởng trước, giúp thợ mỏ phát hiện nguy hiểm và kịp thời rút lui an toàn.

---

## 1. Kiến Trúc Hoạt Động Của Canary Deployment

```
                                  ┌──────────────────────────┐
                                  │   Kubernetes Service     │
                                  │  (selector: app=web-app) │
                                  └─────────────┬────────────┘
                                                │
                     ┌──────────────────────────┴──────────────────────────┐
                     │ 75% Lưu lượng                                       │ 25% Lưu lượng
                     ▼                                                     ▼
       ┌──────────────────────────┐                          ┌──────────────────────────┐
       │  Deployment: web-stable  │                          │  Deployment: web-canary  │
       │     (track: stable)      │                          │     (track: canary)      │
       │    Phiên bản: v1.0       │                          │    Phiên bản: v2.0       │
       │    Số lượng: 3 Pods      │                          │    Số lượng: 1 Pod       │
       └──────────────────────────┘                          └──────────────────────────┘
```

1. **Phân phối rủi ro tối thiểu:** Phiên bản mới chỉ nhận một lượng nhỏ lưu lượng (ví dụ 10% đến 25%). Đa số người dùng vẫn được phục vụ bởi phiên bản ổn định đã được kiểm chứng.
2. **Đo lường thời gian thực:** Đội ngũ kỹ thuật giám sát tỷ lệ lỗi (error rate), độ trễ (latency) và phản hồi thực tế của phiên bản Canary.
3. **Thăng cấp tự tin (Promotion):** Nếu phiên bản Canary chứng minh được độ ổn định, hệ thống sẽ tiến hành cập nhật toàn bộ cụm lên phiên bản mới.
4. **Cô lập và khôi phục tức thì (Zero-impact Rollback):** Nếu phiên bản Canary gặp sự cố, chỉ cần xóa bỏ Deployment Canary. Toàn bộ lưu lượng lập tức quay về phiên bản Stable mà không gây gián đoạn dịch vụ.

---

## 2. Mục Tiêu Bạn Cần Đạt Được Trong Bài Lab Này

* Thiết lập `Service` dùng chung nhãn phân phối lưu lượng giữa nhiều `Deployment`.
* Khởi chạy đồng thời phiên bản `web-stable` (3 Pods) và `web-canary` (1 Pod).
* Thực hiện đo lường tỷ lệ lưu lượng phân bổ và viết script tự động kiểm tra tỷ lệ lỗi.
* Thực thi quy trình thăng cấp an toàn phiên bản v2 lên toàn bộ cụm.
* Giả lập sự cố phiên bản v3 bị lỗi nghiêm trọng và kích hoạt cơ chế thu hồi khẩn cấp.

Nhấn **Next** để bắt đầu bước đầu tiên!
