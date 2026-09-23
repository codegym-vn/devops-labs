# Bước 1: Thu Thập & Bóc Tách Chỉ Số Tài Nguyên (CPU, RAM, Disk)

Trong bước đầu tiên, bạn sẽ tìm hiểu cách hệ điều hành Linux cung cấp thông tin tài nguyên và sử dụng các công cụ dòng lệnh (`free`, `df`, `top`, `awk`, `grep`) để trích xuất số liệu thành các giá trị định lượng có thể lập trình được.

---

## 1. Bóc Tách Chỉ Số RAM (Memory Usage)

Lệnh `free` hiển thị dung lượng bộ nhớ vật lý (RAM) và bộ nhớ ảo (Swap) của hệ thống:

```bash
free -m
```{{exec}}

Cấu trúc đầu ra:
```text
               total        used        free      shared  buff/cache   available
Mem:            1981         350        1005           1         626        1480
Swap:              0           0           0
```

Các trường cần chú ý:
- `total`: Tổng dung lượng RAM vật lý của máy chủ (MB).
- `used`: Dung lượng RAM đang bị chiếm dụng bởi các tiến trình.
- `available`: Dung lượng RAM thực tế còn khả dụng để cấp phát cho tiến trình mới mà không cần swap.

### Trích xuất tỷ lệ phần trăm RAM đã dùng

Để tính phần trăm RAM đã sử dụng theo công thức:
$$\text{RAM\_USAGE (\%)} = \frac{\text{used}}{\text{total}} \times 100$$

Chúng ta sử dụng `awk` để lọc dòng `Mem:` và thực hiện phép chia:

```bash
free -m | awk '/Mem:/ {printf "%.1f", ($3/$2) * 100}'
```{{exec}}

Lệnh trên sẽ in ra một số thực (ví dụ: `17.6`), đại diện cho tỷ lệ % RAM đang sử dụng.

---

## 2. Bóc Tách Chỉ Số Dung Lượng Ổ Đĩa (Disk Usage)

Lệnh `df` (disk free) báo cáo dung lượng không gian đĩa trống trên các hệ thống file. Tùy chọn `-P` (POSIX standard) đảm bảo đầu ra luôn nằm trên 1 dòng duy nhất:

```bash
df -P /
```{{exec}}

Cấu trúc đầu ra:
```text
Filesystem     1024-blocks    Used Available Capacity Mounted on
/dev/sda1         20511312 4194304  15250432      22% /
```

### Trích xuất tỷ lệ % ổ đĩa gốc (`/`)

Dùng `awk` để lấy cột thứ 5 (`Capacity`), sau đó loại bỏ ký tự `%`:

```bash
df -P / | awk 'NR==2 {gsub("%","",$5); print $5}'
```{{exec}}

Kết quả thu được là một số nguyên (ví dụ: `22`), biểu thị phân vùng gốc `/` đã đầy 22%.

---

## 3. Bóc Tách Chỉ Số CPU (CPU Utilization)

Lệnh `top -bn1` chạy `top` ở chế độ batch mode (`-b`), lặp đúng 1 lần (`-n1`) và xuất dữ liệu ra stdout thay vì mở giao diện tương tác:

```bash
top -bn1 | grep "Cpu(s)"
```{{exec}}

Đầu ra mẫu:
```text
%Cpu(s):  2.3 us,  1.0 sy,  0.0 ni, 96.5 id,  0.2 wa,  0.0 hi,  0.0 si,  0.0 st
```

Trong đó:
- `us` (user): Thời gian CPU xử lý các tiến trình của người dùng.
- `sy` (system): Thời gian CPU xử lý các tác vụ kernel hệ điều hành.
- `id` (idle): Thời gian CPU đang rảnh rỗi (không có việc cần xử lý).

Do đó, **CPU đang sử dụng** sẽ bằng: $100 - \text{idle}$.

### Trích xuất % CPU sử dụng bằng `awk`

Tìm vị trí trường `id` trong dòng `Cpu(s)` và lấy $100 - \text{idle}$:

```bash
top -bn1 | grep "Cpu(s)" | awk '{for(i=1;i<=NF;i++) if($i ~ /id/) {gsub(/[^0-9.]/,"",$(i-1)); printf "%.1f", 100 - $(i-1)}}'
```{{exec}}

Lệnh trả về giá trị % tải CPU hiện tại (ví dụ: `3.5`).

---

## 4. Xây Dựng Hàm Thu Thập Trong Bash

Một script giám sát chuyên nghiệp thường tách các logic thu thập vào từng hàm riêng biệt để dễ bảo trì:

```bash
get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk '{for(i=1;i<=NF;i++) if($i ~ /id/) {gsub(/[^0-9.]/,"",$(i-1)); printf "%.1f", 100 - $(i-1)}}'
}

get_ram_usage() {
    free -m | awk '/Mem:/ {printf "%.1f", ($3/$2) * 100}'
}

get_disk_usage() {
    df -P / | awk 'NR==2 {gsub("%","",$5); print $5}'
}
```

---

## 5. Thử Thách & Xác Thực (Verification)

Sau khi đã nắm vững cú pháp bóc tách cả 3 chỉ số tài nguyên, bạn hãy tự tay tạo script giám sát đầu tiên:

### Yêu cầu thử thách:
1. Tạo file script `/root/monitor.sh`.
2. Khai báo shebang `#!/bin/bash` ở dòng đầu tiên.
3. Viết mã để khi thực thi, script in ra đúng một dòng tóm tắt trạng thái hệ thống theo đúng định dạng sau:
   ```text
   CPU: <giá_trị>% | RAM: <giá_trị>% | DISK: <giá_trị>%
   ```
   *(Ví dụ: `CPU: 4.2% | RAM: 18.5% | DISK: 22%`)*
4. Cấp quyền thực thi cho script: `chmod +x /root/monitor.sh`.
5. Tự chạy lệnh `/root/monitor.sh` trên terminal để kiểm tra kết quả hiển thị.

*(Lưu ý: Phần thử thách yêu cầu bạn tự thao tác và gõ lệnh, không có nút chạy tự động)*

<details>
<summary>Xem gợi ý mã mẫu</summary>

Bạn có thể tạo và viết script bằng lệnh `cat`:

```bash
cat << 'EOF' > /root/monitor.sh
#!/bin/bash

get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk '{for(i=1;i<=NF;i++) if($i ~ /id/) {gsub(/[^0-9.]/,"",$(i-1)); printf "%.1f", 100 - $(i-1)}}'
}

get_ram_usage() {
    free -m | awk '/Mem:/ {printf "%.1f", ($3/$2) * 100}'
}

get_disk_usage() {
    df -P / | awk 'NR==2 {gsub("%","",$5); print $5}'
}

CPU=$(get_cpu_usage)
RAM=$(get_ram_usage)
DISK=$(get_disk_usage)

echo "CPU: ${CPU}% | RAM: ${RAM}% | DISK: ${DISK}%"
EOF

chmod +x /root/monitor.sh
/root/monitor.sh
```

</details>

Sau khi hoàn thành và tự kiểm tra script chạy thành công, hãy bấm nút **Check** bên dưới để hệ thống tự động xác thực!
