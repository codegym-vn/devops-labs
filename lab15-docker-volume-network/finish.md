# 🏆 Chúc mừng! Bạn đã hoàn thành Lab: Docker Named Volume & Custom Bridge Network

Bạn vừa tự tay làm chủ cơ chế lưu trữ bền vững và thiết kế kiến trúc mạng an toàn đa tầng cho container trên Docker Host!

---

## 1. Tóm Tắt Kiến Trúc Đã Xây Dựng

```text
 1. Quản Trị Lưu Trữ Bền Vững (Data Persistence):
    • Named Volume (app_data, redis_data) được Docker quản lý tại /var/lib/docker/volumes/
    • Tách rời hoàn toàn dữ liệu khỏi vòng đời ngắn hạn (ephemeral) của container

 2. Mạng Tùy Biến (Custom Bridge Network):
    • Khởi tạo mạng app-net với dải Subnet quy chuẩn 172.28.0.0/16
    • Khám phá cơ chế Embedded DNS Server (127.0.0.11) tự động phân giải tên container

 3. Bảo Mật & Kết Nối Đa Tầng (Multi-tier & Isolation):
    • Triển khai cụm Redis DB và Web Client kết nối nội bộ mà không cần mở cổng ra ngoài
    • Kiểm chứng nguyên tắc Network Isolation: chặn mọi truy cập trái phép từ bên ngoài
    • Thao tác gắn kết nối nóng (Hot Connect) linh hoạt bằng docker network connect
```

---

## 2. Bảng Tra Cứu Lệnh Docker CLI (Cheat Sheet)

### 2.1 — Quản lý Docker Volume
```bash
# Tạo Named Volume
docker volume create <volume_name>

# Liệt kê tất cả volume
docker volume ls

# Xem chi tiết cấu hình và đường dẫn lưu trữ host
docker volume inspect <volume_name>

# Xóa một volume không còn sử dụng
docker volume rm <volume_name>

# Xóa toàn bộ volume rác (dangling volumes)
docker volume prune -f
```

### 2.2 — Quản lý Docker Network
```bash
# Tạo Custom Bridge Network với Subnet
docker network create --driver bridge --subnet <CIDR> <network_name>

# Liệt kê các mạng
docker network ls

# Xem chi tiết cấu hình và các container đang kết nối
docker network inspect <network_name>

# Gắn một container đang chạy vào mạng (Hot Connect)
docker network connect <network_name> <container_name>

# Ngắt một container ra khỏi mạng
docker network disconnect <network_name> <container_name>

# Xóa mạng
docker network rm <network_name>
```

---

## 3. Lệnh Dọn Dẹp Tài Nguyên Sau Khi Hoàn Thành

Để giải phóng bộ nhớ và tài nguyên trên máy chủ của bạn sau khi kết thúc bài thực hành:

```bash
# Dọn dẹp toàn bộ container đã tạo trong bài lab
docker rm -f reader-box service-alpha service-beta redis-db web-client isolated-box 2>/dev/null

# Dọn dẹp mạng custom
docker network rm app-net 2>/dev/null

# Dọn dẹp các volume đã tạo
docker volume rm app_data redis_data 2>/dev/null

echo "✅ Đã dọn dẹp sạch sẽ tài nguyên bài thực hành!"
```
