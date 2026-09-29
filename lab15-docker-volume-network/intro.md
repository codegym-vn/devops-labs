# Lab 15: Thực Hành Khởi Tạo Named Volume, Cấu Hình Custom Bridge Network & Kết Nối Container

Chào mừng bạn đến với bài thực hành chuyên sâu về **Docker Storage** và **Docker Networking**. Trong bài lab này, bạn sẽ làm chủ kỹ thuật lưu trữ dữ liệu bền vững với **Named Volume**, xây dựng mạng riêng biệt với **Custom Bridge Network**, và thiết lập cơ chế khám phá dịch vụ tự động (**Service Discovery**) qua **Embedded DNS**.

---

## 1. Kiến Trúc Hệ Thống Cần Triển Khai

```
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Docker Host (Ubuntu Engine)                                                │
 │                                                                             │
 │  ┌───────────────────────────────────────────────────────────────────────┐  │
 │  │ Custom Bridge Network: app-net (172.28.0.0/16)                        │  │
 │  │ Embedded DNS Server (127.0.0.11)                                      │  │
 │  │                                                                       │  │
 │  │   ┌───────────────────────────┐       ┌───────────────────────────┐   │  │
 │  │   │ Container: web-client     │       │ Container: redis-db       │   │  │
 │  │   │ IP: 172.28.0.x            │       │ IP: 172.28.0.y            │   │  │
 │  │   │                           │       │ Port: 6379                │   │  │
 │  │   │ Truy vấn qua tên:         │──────►│                           │   │  │
 │  │   │ "redis-db:6379"           │       └─────────────┬─────────────┘   │  │
 │  │   └───────────────────────────┘                     │                 │  │
 │  └─────────────────────────────────────────────────────┼─────────────────┘  │
 │                                                        │                    │
 │                                             Mount: -v redis_data:/data      │
 │                                                        │                    │
 │                                                        ▼                    │
 │                                          ┌───────────────────────────┐      │
 │                                          │ Named Volume: redis_data  │      │
 │                                          │ (/var/lib/docker/volumes) │      │
 │                                          └───────────────────────────┘      │
 └─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Vì Sao Cần Named Volume & Custom Bridge Network?

* **Lưu Trữ Bền Vững (Data Persistence):** Mặc định, tầng ghi (Writable Layer) của container có tính chất tạm thời (Ephemeral). Khi container bị xóa (`docker rm`), toàn bộ dữ liệu sinh ra sẽ biến mất vĩnh viễn. **Named Volume** được Docker quản lý độc lập tại `/var/lib/docker/volumes/`, dữ liệu vẫn tồn tại an toàn ngay cả khi container bị hủy.
* **Cơ Chế Khám Phá Dịch Vụ (Embedded DNS):** Mạng mặc định (`default bridge`) không hỗ trợ phân giải IP qua tên container. Ngược lại, **Custom Bridge Network** tích hợp sẵn máy chủ DNS nội bộ tại `127.0.0.11`, cho phép các container tự động liên lạc với nhau qua chính tên định danh (`container_name`), giúp loại bỏ việc gán cứng IP dễ gây lỗi.
* **Cô Lập Mạng (Network Isolation):** Các container nằm ở các mạng khác nhau hoàn toàn không thể giao tiếp trực tiếp, ngăn chặn nguy cơ tấn công leo thang và đảm bảo an toàn cho tầng CSDL/Cache.

---

## 3. Mục Tiêu

- Hiểu bản chất lưu trữ dữ liệu bền vững và vòng đời của Named Volume
- Tạo và quản trị Custom Bridge Network với dải Subnet quy hoạch chuẩn
- Vận dụng Embedded DNS để kết nối liên container mà không cần IP tĩnh
- Xây dựng mô hình ứng dụng đa tầng (Multi-tier) an toàn và kiểm chứng tính cô lập mạng
