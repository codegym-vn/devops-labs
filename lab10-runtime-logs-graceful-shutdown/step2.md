# Bước 2: Giới Hạn Tài Nguyên (CPU/RAM, OOM Killer) & Quản Lý Log Container

Trong môi trường đa ứng dụng, việc không giới hạn tài nguyên sẽ dẫn tới hiện tượng "hàng xóm ồn ào" (Noisy Neighbor) - một container bị lỗi rò rỉ bộ nhớ (Memory Leak) có thể ngốn sạch tài nguyên máy chủ và kéo theo tất cả các dịch vụ khác bị sập.

---

## 1. Cơ Chế Giới Hạn Tài Nguyên (cgroups Linux)

Docker sử dụng tính năng **Control Groups (cgroups)** của Linux kernel để áp đặt hạn ngạch tài nguyên phần cứng cho từng container.

### Giới Hạn CPU (`--cpus`)
- `--cpus 0.5`: Giới hạn container chỉ được sử dụng tối đa 50% năng lực tính toán của 1 nhân CPU (50000 microsecond quota trong chu kỳ 100000 microsecond CFS period).

### Giới Hạn Bộ Nhớ RAM & Swap
- `--memory 128m`: Giới hạn bộ nhớ vật lý tối đa là 128 Megabytes.
- `--memory-swap 128m`: Đặt giá trị swap bằng đúng giá trị memory đồng nghĩa với việc **vô hiệu hóa hoàn toàn swap** cho container này. Nếu không đặt cờ này, Docker mặc định cho phép swap gấp đôi lượng RAM, khiến ứng dụng khi thiếu RAM sẽ ghi dữ liệu xuống đĩa làm tốc độ xử lý sụt giảm nghiêm trọng.

Khảo sát mức tiêu thụ tài nguyên thời gian thực với `docker stats`:

```bash
docker run -d --name test-limits --cpus 0.5 --memory 128m --memory-swap 128m alpine:3.19 sleep 60
docker stats --no-stream test-limits
docker rm -f test-limits
```{{exec}}

---

## 2. Thực Nghiệm Mô Phỏng Linux OOM Killer

Khi một tiến trình bên trong container cố tình cấp phát bộ nhớ vượt quá ngưỡng `--memory` cho phép và không còn bộ nhớ swap, Linux kernel sẽ kích hoạt cơ chế **OOM (Out Of Memory) Killer** để bảo vệ hệ điều hành chủ.

Kernel sẽ gửi trực tiếp tín hiệu `SIGKILL` (mã 9) để tiêu diệt tiến trình vi phạm. Khi đó:
- Mã thoát của container là: **`137`** (công thức: `128 + 9 = 137`).
- Cờ trạng thái container: **`OOMKilled: true`**.

Hãy thử nghiệm với script `/root/app/oom_test.py` (liên tục cấp phát các khối RAM 20MB) trên một container bị giới hạn 64MB RAM:

```bash
docker run --name test-oom --memory 64m --memory-swap 64m \
  -v /root/app/oom_test.py:/app/oom_test.py \
  python:3.11-alpine python /app/oom_test.py
```{{exec}}

Sau khi tiến trình bị ngắt đột ngột, hãy kiểm tra mã thoát và cờ OOM:

```bash
docker inspect -f 'ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}' test-oom
docker rm test-oom
```{{exec}}

Kết quả `ExitCode: 137` và `OOMKilled: true` minh chứng rõ ràng việc kernel đã can thiệp xử lý kịp thời để bảo vệ hệ thống.

---

## 3. Quản Lý Log Container & Cơ Chế Xoay Vòng Log (Log Rotation)

Mặc định, Docker sử dụng driver `json-file` và ghi toàn bộ dữ liệu từ `stdout`/`stderr` vào file text trên host (`/var/lib/docker/containers/<id>/...-json.log`).

**Nguy cơ thực tế**: Nếu ứng dụng ghi log liên tục hàng chục GB mà không có cơ chế xoay vòng (Log Rotation), ổ đĩa máy chủ sẽ bị đầy 100%, khiến Docker daemon và toàn bộ máy chủ bị tê liệt!

### Cấu Hình Xoay Vòng Log (Log Rotation Options)
- `--log-opt max-size=2m`: Giới hạn dung lượng tối đa của 1 file log là 2MB. Khi vượt ngưỡng, Docker tự động nén hoặc tạo file log mới.
- `--log-opt max-file=3`: Giữ lại tối đa 3 file log cũ (dung lượng log của container này sẽ không bao giờ vượt quá `2MB x 3 = 6MB`).

Khởi chạy container thử nghiệm tính năng xoay vòng log:

```bash
docker run -d --name test-logs \
  --log-opt max-size=2m --log-opt max-file=3 \
  alpine:3.19 sh -c 'for i in $(seq 1 100); do echo "{\"seq\": $i, \"level\": \"INFO\", \"msg\": \"He thong hoat dong on dinh\"}"; done'
```{{exec}}

Kiểm tra log bằng lệnh `docker logs` kết hợp `jq` để lọc các log có cấu trúc:

```bash
docker logs test-logs | tail -n 5 | jq .
docker rm -f test-logs
```{{exec}}

---

## 4. Thử Thách Thực Hành (DIY Challenge)

Hãy khởi chạy container dịch vụ dữ liệu chuẩn mực mang tên **`data-service`** đáp ứng các tiêu chuẩn khắt khe về giới hạn tài nguyên và log:

1. Tên container: **`data-service`**
2. Image sử dụng: **`alpine:3.19`**
3. Chế độ chạy: Chạy ngầm dưới nền (**`-d`**)
4. Lệnh thực thi giữ tiến trình: **`sh -c "while true; do sleep 3600; done"`**
5. Giới hạn CPU: Tối đa **`0.5`** core (**`--cpus 0.5`**)
6. Giới hạn RAM vật lý: Tối đa **`256MB`** (**`--memory 256m`**)
7. Giới hạn Swap: Tối đa **`256MB`** (**`--memory-swap 256m`**)
8. Cấu hình xoay vòng log: Kích thước tối đa mỗi file **`2MB`** (**`--log-opt max-size=2m`**) và số lượng file lưu trữ tối đa là **`3`** (**`--log-opt max-file=3`**)

Sau khi container được khởi chạy, hãy bấm nút **Check** ở góc trên để hệ thống tự động kiểm định cấu hình cgroups và logging driver.
