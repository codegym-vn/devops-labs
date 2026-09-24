# Bước 3: Tín Hiệu OS Signals, Vấn Đề PID 1 & Kiểm Thử Graceful Shutdown

Trong môi trường điện toán đám mây hiện đại (CI/CD liên tục, Kubernetes Auto-scaling, Rolling Update), container thường xuyên được khởi tạo và hủy bỏ liên tục. Nếu ứng dụng bị ép dừng đột ngột mà không có cơ chế **Graceful Shutdown**, dữ liệu đơn hàng đang thanh toán dở dang có thể bị lỗi, file bị hỏng (corrupted), và người dùng sẽ nhận về mã lỗi HTTP 502/504 Bad Gateway.

---

## 1. Bản Chất Các Tín Hiệu Hệ Điều Hành (UNIX Signals)

Khi bạn thực hiện thao tác dừng một container, Docker giao tiếp với tiến trình thông qua các tín hiệu hệ điều hành:

```text
docker stop ──> Gửi SIGTERM (15) ──> Đợi Grace Period (10s) ──> Nếu chưa tắt ──> Gửi SIGKILL (9)
                      │                                                                 │
                      ▼                                                                 ▼
             [Ứng dụng bắt tín hiệu]                                            [Kernel ép chết ngay]
             - Dừng nhận request mới                                            - Bỏ dở giao dịch
             - Xử lý nốt in-flight request                                      - Mất mát dữ liệu
             - Đóng Pool DB, flush cache                                        - Mã lỗi Exit 137
             - Tắt sạch sẽ (Exit code 0)
```

- **`SIGTERM` (Signal 15 - Termination)**: Lời yêu cầu lịch sự gửi tới tiến trình để thu dọn tài nguyên và tự kết thúc.
- **`SIGKILL` (Signal 9 - Kill)**: Tín hiệu cưỡng chế từ kernel. Tiến trình bị hủy diệt tức thì mà không thể chạy bất kỳ hàm dọn dẹp nào.

---

## 2. Cạm Bẫy Tiến Trình PID 1 Trong Container

Trong Linux, tiến trình mang **PID 1** (Init system) có cơ chế xử lý tín hiệu rất đặc biệt: Kernel không áp dụng các bộ xử lý tín hiệu mặc định (default signal handler). Nếu tiến trình không tự cài đặt hàm bắt tín hiệu, nó sẽ **hoàn toàn làm ngơ trước SIGTERM**!

### Cạm Bẫy Shell Form vs Exec Form:
- **Dạng Shell Form**: `CMD python server.py`
  - Docker sẽ khởi chạy: `/bin/sh -c "python server.py"`.
  - PID 1 là `/bin/sh`. Shell này **nuốt mất tín hiệu SIGTERM** và không chuyển tiếp cho tiến trình con Python. Kết quả: Sau 10 giây chờ đợi trong vô vọng, Docker buộc phải gửi `SIGKILL` (tiến trình chết đột ngột với Exit code 137).
- **Dạng Exec Form**: `CMD ["python", "server.py"]`
  - Ứng dụng Python trực tiếp là PID 1, bắt được `SIGTERM` và kích hoạt hàm dọn dẹp tức thì.

---

## 3. Khám Phá Quy Trình Graceful Shutdown Mẫu

Một quy trình rút lui an toàn (Graceful Teardown) chuẩn bao gồm 4 bước:
1. **Bắt tín hiệu `SIGTERM`**: Ngăn tiến trình bị chết đột ngột.
2. **Từ chối kết nối mới**: Trả về `503 Service Unavailable` để các hệ thống cân bằng tải (Nginx / Ingress Controller) chuyển traffic sang node khác.
3. **Rút cạn kết nối đang xử lý (Connection Draining)**: Cho phép các request đang xử lý dở được hoàn tất bình thường.
4. **Giải phóng tài nguyên**: Đóng kết nối cơ sở dữ liệu, ngắt socket và gọi `sys.exit(0)`.

Xem mã nguồn ứng dụng mẫu đã được tích hợp sẵn đầy đủ cơ chế trên tại `/root/app/server.py`:

```bash
cat /root/app/server.py
```{{exec}}

---

## 4. Thử Nghiệm Tắt An Toàn Với Request Đang Xử Lý

Hãy chạy thử nghiệm để tận mắt quan sát cơ chế bảo vệ giao dịch:

1. Khởi chạy ứng dụng Web mẫu:
   ```bash
   docker run -d --name demo-graceful -p 8080:8080 \
     -v /root/app/server.py:/app/server.py \
     python:3.11-alpine python3 /app/server.py
   ```{{exec}}

2. Gửi một tác vụ giả lập xử lý nặng mất 3 giây (`/work`) chạy nền:
   ```bash
   curl -s http://localhost:8080/work &
   ```{{exec}}

3. Ngay lập tức gửi lệnh dừng container:
   ```bash
   docker stop -t 10 demo-graceful
   ```{{exec}}

4. Quan sát: Lệnh `curl` vẫn in ra kết quả thành công `{"status": "success", "message": "Work completed successfully"}` trước khi container dừng hẳn!

5. Kiểm tra mã thoát của container:
   ```bash
   docker inspect -f 'ExitCode: {{.State.ExitCode}}' demo-graceful
   docker rm demo-graceful
   ```{{exec}}

Kết quả `ExitCode: 0` chứng minh ứng dụng đã hoàn tất giao dịch an toàn và tắt êm đềm trước khi timeout 10 giây kết thúc.

---

## 5. Thử Thách Thực Hành (DIY Challenge)

Hãy tự mình thiết lập và thực hiện kiểm thử Graceful Shutdown cho ứng dụng chính thức:

1. Khởi chạy container với tên **`graceful-app`** bằng image **`python:3.11-alpine`**
2. Gắn volume mã nguồn: **`-v /root/app/server.py:/app/server.py`**
3. Ánh xạ cổng: **`-p 8080:8080`**
4. Chạy dưới dạng daemon nền: **`-d`**
5. Lệnh thực thi trực tiếp dạng Exec Form: **`python3 /app/server.py`**
6. Gửi một request giả lập xử lý công việc chạy nền:
   ```bash
   curl -s http://localhost:8080/work &
   ```
7. Ra lệnh tắt container an toàn:
   ```bash
   docker stop -t 10 graceful-app
   ```
8. Xác nhận kết quả trong log và mã thoát:
   - Container chuyển về trạng thái `exited` với mã thoát đúng bằng **`0`**.
   - Log container ghi nhận thông điệp `Graceful exit`.

Sau khi hoàn tất, hãy bấm nút **Check** ở góc trên để hệ thống tự động kiểm tra tính toàn vẹn của tiến trình Graceful Shutdown.
