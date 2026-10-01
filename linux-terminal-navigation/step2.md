# Bước 2: Nghệ Thuật Điều Hướng Cây Thư Mục Linux Với cd

Trong hệ điều hành Linux, mọi thứ đều được tổ chức dưới dạng một cây thư mục phân cấp duy nhất (**Tree Structure**). Không giống như Windows phân chia thành các ổ đĩa độc lập (`C:\`, `D:\`), Linux bắt đầu từ một gốc duy nhất được ký hiệu là dấu gạch chéo **`/` (Root Directory)**.

---

## 1. Cấu Trúc Cây Thư Mục Chuẩn FHS (Filesystem Hierarchy Standard)

Để làm việc hiệu quả và không bị lạc trong hệ thống, kỹ sư DevOps cần ghi nhớ bản đồ các thư mục cốt lõi sau:

```
/ (Root Directory)
├── bin -> usr/bin       # Chứa các lệnh nhị phân thực thi cơ bản (ls, cp, rm, bash)
├── etc/                 # Nơi lưu trữ toàn bộ FILE CẤU HÌNH hệ thống & ứng dụng (nginx, ssh, hosts)
├── home/                # Thư mục cá nhân của người dùng thông thường (/home/ubuntu)
├── root/                # Thư mục cá nhân riêng biệt của superuser root (/root)
├── var/                 # Dữ liệu biến đổi (Variable data)
│   └── log/             # THƯ MỤC LOGS HỆ THỐNG - nơi kỹ sư DevOps tìm dấu vết lỗi
├── tmp/                 # Thư mục tạm thời, bất kỳ ai cũng có thể ghi, tự xóa định kỳ
└── usr/                 # Chương trình người dùng, thư viện chia sẻ (/usr/local/bin)
```

---

## 2. Phân Biệt Tuyệt Đối (Absolute) vs Tương Đối (Relative Path)

| Loại Đường Dẫn | Điểm Bắt Đầu | Đặc Điểm Nhận Dạng | Ví Dụ Thực Tế | Khi Nào Sử Dụng? |
|---|---|---|---|---|
| **Tuyệt Đối (Absolute)** | Luôn bắt đầu từ gốc **`/`** | Bất kể bạn đang đứng ở đâu, đường dẫn luôn trỏ tới chính xác cùng một vị trí | `/etc/nginx/nginx.conf`<br>`/var/log/syslog` | Dùng trong Script tự động hóa, Cronjob, Dockerfile để đảm bảo 100% không bị lệch vị trí. |
| **Tương Đối (Relative)** | Bắt đầu từ vị trí bạn đang đứng (**`$PWD`**) | Không có dấu `/` ở đầu | `nginx.conf`<br>`../configs/app.env` | Dùng khi thao tác thủ công nhanh trên terminal bên trong một project. |

---

## 3. Các Ký Hiệu Quy Ước Vàng Trong Điều Hướng

Khi sử dụng lệnh `cd` (**Change Directory**), hãy làm chủ 4 ký hiệu đặc biệt sau:

- **`.` (Một dấu chấm):** Đại diện cho thư mục hiện tại.
- **`..` (Hai dấu chấm):** Đại diện cho thư mục cha (cấp trên liền kề).
- **`~` (Dấu ngã):** Đại diện cho thư mục Home của người dùng hiện tại (`/root` hoặc `/home/<user>`).
- **`-` (Dấu gạch ngang):** Đưa bạn quay trở lại thư mục vừa đứng ngay trước đó (dựa trên biến môi trường `$OLDPWD`).

---

## 4. Thực Hành: Khám Phá Và Điều Hướng Qua Lại

### 4.1. Điều hướng bằng đường dẫn tuyệt đối
Hãy di chuyển vào thư mục chứa file cấu hình hệ thống:

```bash
cd /etc
pwd
```{{exec}}

### 4.2. Lùi cấp bằng đường dẫn tương đối (`..`)
Lùi về một cấp (chính là thư mục gốc `/`):

```bash
cd ..
pwd
```{{exec}}

### 4.3. Nhảy nhanh về thư mục Home (`~` hoặc `cd`)
Dù đang ở bất kỳ đâu, chỉ cần gõ `cd` hoặc `cd ~`:

```bash
cd ~
pwd
```{{exec}}

### 4.4. Siêu kỹ thuật chuyển đổi thư mục với `cd -`
Trong DevOps, bạn thường xuyên phải di chuyển giữa thư mục mã nguồn dự án và thư mục log hệ thống để kiểm tra lỗi. 

Hãy di chuyển vào `/var/log`:

```bash
cd /var/log
pwd
```{{exec}}

Sau đó di chuyển vào `/etc/systemd`:

```bash
cd /etc/systemd
pwd
```{{exec}}

Bây giờ, chỉ cần dùng lệnh `cd -` để nhảy ngược về `/var/log` ngay lập tức mà không cần gõ lại đường dẫn dài:

```bash
cd -
pwd
```{{exec}}

Gõ tiếp `cd -` một lần nữa để nhảy lại `/etc/systemd`:

```bash
cd -
pwd
```{{exec}}

---

## 5. Thử Thách Bước 2: Chinh Phục Cung Đường Điều Hướng

**Nhiệm vụ của bạn:**
Thực hiện chính xác chuỗi thao tác sau trên Terminal:

1. Di chuyển vào thư mục `/etc` bằng đường dẫn tuyệt đối:
   ```bash
   cd /etc
   ```
2. Từ `/etc`, dùng đường dẫn tương đối để di chuyển sang thư mục log `/var/log`:
   ```bash
   cd ../var/log
   ```
3. Sử dụng lệnh quay lại thư mục trước đó để trở về `/etc`:
   ```bash
   cd -
   ```
4. Ghi lại đường dẫn hiện tại vào file `/tmp/nav_checkpoint.txt`:
   ```bash
   pwd > /tmp/nav_checkpoint.txt
   ```
5. Từ vị trí hiện tại (`/etc`), dùng đường dẫn tương đối với `..` để tạo một tệp rỗng tại `/tmp/.nav_reached`:
   ```bash
   touch ../tmp/.nav_reached
   ```

Sau khi hoàn thành, hãy nhấn nút **Check** để hệ thống kiểm tra và xác nhận lộ trình điều hướng của bạn!
