# Bước 1: Vòng Đời Container & Cấu Hình Tham Số Runtime

Để vận hành container trong môi trường thực tế, kỹ sư cần kiểm soát chính xác từng giai đoạn sống của tiến trình và cung cấp cấu hình runtime linh hoạt mà không làm thay đổi image gốc.

---

## 1. Khám Phá Vòng Đời Container (Container Lifecycle)

Container không phải là một máy ảo hoàn chỉnh, mà là một tiến trình Linux cô lập được quản lý bởi Docker daemon. Vòng đời của container trải qua các trạng thái:

```text
[Image] ──docker create──> [Created] ──docker start──> [Running]
                                                          │
                    ┌───────────────┬─────────────────────┤
                    │ docker pause  │ docker stop         │ Crash / OOM
                    ▼               ▼                     ▼
                [Paused]        [Stopped (Exited)]    [Stopped (Exited)]
                    │               │                     │
             docker unpause         └──────docker rm──────┴──> [Deleted]
```

Kiểm tra trạng thái chi tiết của container bằng cú pháp `docker inspect`:

```bash
docker run -d --name demo-lifecycle alpine:3.19 sleep 100
docker inspect -f 'Trang thai: {{.State.Status}} | PID: {{.State.Pid}}' demo-lifecycle
```{{exec}}

Tạm dừng (freeze) và tiếp tục tiến trình bằng cgroups freezer:

```bash
docker pause demo-lifecycle
docker inspect -f 'Trang thai sau pause: {{.State.Status}}' demo-lifecycle
docker unpause demo-lifecycle
```{{exec}}

Dừng và dọn dẹp container:

```bash
docker stop demo-lifecycle
docker rm demo-lifecycle
```{{exec}}

---

## 2. Quản Lý Biến Môi Trường (Environment Variables)

Theo nguyên tắc 12-Factor App, toàn bộ thông tin cấu hình (cổng kết nối, môi trường, secret) phải được tách biệt khỏi mã nguồn và truyền vào container qua biến môi trường.

Docker hỗ trợ 2 phương thức:
1. **Truyền trực tiếp qua cờ `-e`**: Phù hợp cho các thiết lập nhanh.
   ```bash
   docker run -d --name test-env -e APP_PORT=3000 -e ENV=dev alpine:3.19 sleep 60
   docker exec test-env env | grep -E "APP_PORT|ENV"
   docker rm -f test-env
   ```{{exec}}
2. **Nạp hàng loạt qua file cấu hình `--env-file`**: Phù hợp cho production, giúp bảo mật và dễ quản lý phiên bản cấu hình.

Xem trước file cấu hình mẫu đã được chuẩn bị tại `/root/app/.env.app`:

```bash
cat /root/app/.env.app
```{{exec}}

---

## 3. Cấu Hình Cổng Mạng & Chính Sách Phục Hồi (Restart Policy)

### Port Mapping (`-p host_port:container_port`)
Container có không gian mạng riêng (Network Namespace). Để bên ngoài có thể truy cập dịch vụ, Docker sử dụng iptables để NAT lưu lượng từ cổng host vào container:
- `-p 8080:80`: Ánh xạ cổng 8080 của máy chủ host vào cổng 80 bên trong container.

### Chính Sách Tự Khởi Động Lại (`--restart`)
Khi tiến trình chính bên trong container bị crash hoặc khi máy chủ Docker khởi động lại, chính sách `--restart` quyết định hành vi:

| Chính Sách | Mô Tả Hành Vi | Khi Nào Sử Dụng |
|---|---|---|
| `no` | Mặc định. Không tự khởi động lại trong mọi trường hợp. | Các tác vụ chạy 1 lần (batch jobs, migrations). |
| `on-failure[:max]` | Chỉ khởi động lại nếu tiến trình thoát với mã lỗi khác 0. Có thể giới hạn số lần thử. | Dịch vụ background cần tự phục hồi nhưng tránh loop vô hạn. |
| `always` | Luôn tự khởi động lại bất kể mã thoát. Nếu người dùng stop thủ công, nó sẽ chỉ khởi động lại khi Docker daemon restart. | Các dịch vụ hạ tầng quan trọng. |
| `unless-stopped` | Tương tự `always`, nhưng nếu đã bị `docker stop` thủ công thì sẽ giữ nguyên trạng thái dừng kể cả khi khởi động lại máy chủ. | **Khuyên dùng cho phần lớn ứng dụng Production**. |

---

## 4. Thử Thách Thực Hành (DIY Challenge)

Hãy vận dụng các kiến thức trên để thiết lập một container dịch vụ chuẩn chỉnh theo yêu cầu sau:

1. Tên container: **`web-runtime`**
2. Image sử dụng: **`alpine:3.19`**
3. Chế độ chạy: Chạy ngầm dưới dạng background daemon (**`-d`**)
4. Lệnh thực thi giữ tiến trình hoạt động: **`sh -c "while true; do sleep 3600; done"`**
5. Biến môi trường: Nạp toàn bộ từ file **`/root/app/.env.app`** (sử dụng cờ `--env-file`)
6. Ánh xạ cổng mạng: Cổng host **`8080`** trỏ vào cổng container **`8080`** (**`-p 8080:8080`**)
7. Chính sách phục hồi: **`--restart unless-stopped`**

Sau khi container được khởi chạy thành công, hãy bấm nút **Check** ở góc trên để hệ thống tự động kiểm tra tính chính xác của toàn bộ tham số runtime.
