# Bước 1: Giải Mã Prompt, Cấu Trúc Lệnh & Thẩm Tra Môi Trường

Khi lần đầu tiên mở Terminal hoặc kết nối SSH vào một máy chủ từ xa, bạn sẽ bắt gặp một dòng chữ kèm con trỏ nhấp nháy. Dòng chữ này được gọi là **Terminal Prompt**.

---

## 1. Giải Mã Cấu Trúc Terminal Prompt

Hãy quan sát dòng nhắc lệnh trên terminal của bạn, thường có dạng:

```text
root@node01:~#
```
hoặc đối với người dùng thông thường:
```text
ubuntu@node01:~$
```

Chuỗi ký tự này được cấu thành từ 5 thành phần quan trọng:

```
  root   @   node01   :   ~   #
  |          |            |   |
  |          |            |   +--> Ký hiệu đặc quyền (#: root, $: user thường)
  |          |            +------> Thư mục làm việc hiện tại (~ là thư mục Home)
  |          +-------------------> Tên máy chủ (Hostname)
  +------------------------------> Tên người dùng đang đăng nhập (Username)
```

> **Quy tắc an toàn trong DevOps:**
> - Ký tự kết thúc là **`$`**: Bạn đang là **người dùng thông thường (Non-root user)**. Bạn bị giới hạn quyền sửa đổi cấu hình hệ thống và cần dùng `sudo` khi muốn chạy quyền quản trị.
> - Ký tự kết thúc là **`#`**: Bạn đang là **Superuser (Root)** — quyền lực cao nhất của hệ điều hành Linux. Mỗi lệnh bạn gõ với quyền root có thể xóa sạch toàn bộ máy chủ nếu mắc lỗi bất cẩn!

---

## 2. Quy Tắc Cú Pháp Lệnh Linux Tiêu Chuẩn

```text
command [options/flags] [arguments]
```

- **`command` (Tên lệnh):** Hành động muốn thực hiện (ví dụ: `ls`, `mkdir`, `rm`, `date`).
- **`options` (Tùy chọn / Cờ hiệu):** Tinh chỉnh hành vi của lệnh, thường bắt đầu bằng dấu gạch ngang:
  - *Cờ ngắn (Short option):* Gồm 1 dấu gạch ngang và 1 ký tự (ví dụ: `-l`, `-a`, `-h`). Ta có thể gộp nhiều cờ ngắn lại cùng nhau: `-lah`.
  - *Cờ dài (Long option):* Gồm 2 dấu gạch ngang kèm từ đầy đủ (ví dụ: `--all`, `--human-readable`).
- **`arguments` (Đối số):** Đối tượng mà lệnh sẽ tác động lên (ví dụ: tên file, đường dẫn thư mục, chuỗi văn bản).

---

## 3. Thực Hành: Bộ Lệnh Thẩm Tra Nhận Dạng Hệ Thống

Khi vừa đăng nhập vào một máy chủ bất kỳ, kỹ sư DevOps luôn cần xác định ngay: *Tôi là ai? Tôi đang đứng ở máy nào? Và tôi đang ở đâu?*

### 3.1. Xác định tài khoản hiện hành (`whoami` & `id`)
Chạy lệnh kiểm tra tên tài khoản:

```bash
whoami
```{{exec}}

Để xem chi tiết mã định danh người dùng (UID), mã định danh nhóm (GID) và các nhóm hệ thống mà tài khoản trực thuộc:

```bash
id
```{{exec}}

Quan sát: Nếu là tài khoản `root`, bạn sẽ thấy `uid=0(root) gid=0(root)`. Trong Linux, bất kỳ tài khoản nào mang `uid=0` đều là tài khoản quản trị tối cao.

### 3.2. Xác định tên máy chủ (`hostname`)
Trong môi trường Cloud với hàng chục cụm máy chủ, lệnh này giúp bạn chắc chắn mình không thao tác nhầm trên môi trường Production:

```bash
hostname
```{{exec}}

### 3.3. Kiểm tra thông tin nhân Linux (`uname -a`)
Kiểm tra kiến trúc CPU (x86_64, arm64) và phiên bản Linux Kernel đang chạy:

```bash
uname -a
```{{exec}}

### 3.4. Kiểm tra thời gian hệ thống (`date`)
Đồng bộ thời gian là yếu tố sống còn khi kiểm tra log hệ thống và phân tích sự cố:

```bash
date
```{{exec}}

Bạn có thể định dạng thời gian theo chuẩn ISO 8601 thường dùng trong logging:

```bash
date +"%Y-%m-%d %H:%M:%S"
```{{exec}}

### 3.5. Xác định thư mục làm việc hiện tại (`pwd`)
Lệnh `pwd` là viết tắt của **Print Working Directory**:

```bash
pwd
```{{exec}}

Kết quả in ra là đường dẫn tuyệt đối của thư mục bạn đang đứng (ví dụ: `/root`).

---

## 4. Biến Môi Trường Cốt Lõi (Environment Variables)

Linux lưu trữ các thông tin phiên làm việc trong các biến môi trường đặc biệt (viết hoa). Hãy dùng lệnh `echo` để kiểm tra:

```bash
echo "User: $USER"
echo "Home Directory: $HOME"
echo "Current Shell: $SHELL"
echo "Working Directory: $PWD"
```{{exec}}

---

## 5. Thử Thách Bước 1: Tạo Hồ Sơ Định Danh Máy Chủ

**Nhiệm vụ của bạn:**
Hãy tạo một tệp tin tại đường dẫn `/tmp/system_identity.txt` chứa đúng 3 dòng thông tin của phiên làm việc hiện tại theo định dạng sau:

```text
USER: <kết quả của lệnh whoami>
HOSTNAME: <kết quả của lệnh hostname>
CURRENT_DIR: <kết quả của lệnh pwd khi đứng tại thư mục làm việc hiện tại>
```

> **Gợi ý thực hiện:**
> Bạn có thể sử dụng toán tử điều hướng ghi đè `>` cho dòng đầu tiên và toán tử ghi nối tiếp `>>` cho các dòng tiếp theo:
> ```bash
> echo "USER: $(whoami)" > /tmp/system_identity.txt
> echo "HOSTNAME: $(hostname)" >> /tmp/system_identity.txt
> echo "CURRENT_DIR: $(pwd)" >> /tmp/system_identity.txt
> ```
> Sau đó dùng lệnh `cat /tmp/system_identity.txt` để kiểm tra lại nội dung tệp.

Sau khi hoàn thành, hãy nhấn nút **Check** để hệ thống tự động kiểm tra kết quả!
