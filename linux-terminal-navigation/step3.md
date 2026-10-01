# Bước 3: Quản Trị Tệp & Cấu Trúc Thư Mục Dự Án

Trong các pipeline CI/CD và quy trình triển khai ứng dụng, bạn sẽ liên tục phải tạo thư mục chứa mã nguồn, sao chép file cấu hình môi trường (`.env`), sao lưu dữ liệu và dọn dẹp các tệp rác. Làm chủ các thao tác này là điều kiện tiên quyết trước khi tiếp cận Docker và Kubernetes.

---

## 1. Tạo Thư Mục Đa Cấp Với `mkdir -p`

Lệnh `mkdir` (**Make Directory**) dùng để tạo thư mục mới. Tuy nhiên, nếu bạn muốn tạo một đường dẫn gồm nhiều cấp thư mục lồng nhau, lệnh `mkdir` thông thường sẽ báo lỗi `No such file or directory`.

Để giải quyết vấn đề này, hãy luôn ghi nhớ cờ **`-p` (Parents)**:
- Tự động tạo tất cả các thư mục cha trung gian nếu chúng chưa tồn tại.
- Không báo lỗi nếu thư mục đích đã có sẵn (rất an toàn khi viết script tự động hóa).

```bash
mkdir -p /tmp/demo-project/sub1/sub2
```{{exec}}

### Mẹo DevOps: Kết hợp kỹ thuật Brace Expansion của Bash
Bạn có thể khởi tạo hàng loạt thư mục nhánh cùng cấp chỉ với một dòng lệnh:

```bash
mkdir -p /tmp/my-app/{src,configs,logs,tests}
ls -l /tmp/my-app
```{{exec}}

---

## 2. Tạo Tệp Nhanh Bằng `touch`

Lệnh `touch` có 2 công dụng chính:
1. **Tạo file rỗng mới** nếu file chưa tồn tại.
2. **Cập nhật mốc thời gian truy cập/sửa đổi (timestamp)** của file về thời điểm hiện tại nếu file đã có sẵn (thường dùng để kích hoạt các công cụ build tự động phát hiện thay đổi).

```bash
touch /tmp/my-app/src/index.js
touch /tmp/my-app/configs/app.conf
```{{exec}}

---

## 3. Trực Quan Hóa Cây Thư Mục Với `tree`

Để có cái nhìn tổng quan về kiến trúc dự án thay vì gõ `ls` từng thư mục, hãy sử dụng lệnh `tree`:

```bash
tree /tmp/my-app
```{{exec}}

> **Mẹo hữu ích:** Khi làm việc trong các dự án lớn (như node_modules hay mã nguồn sâu), hãy dùng thêm cờ `-L <số-tầng>` để giới hạn độ sâu hiển thị: `tree -L 2 /tmp/my-app`.

---

## 4. Sao Chép Với `cp` & Di Chuyển / Đổi Tên Với `mv`

### 4.1. Sao chép tệp tin (`cp`)
Sao chép một file nguồn sang file đích:

```bash
cp /tmp/my-app/configs/app.conf /tmp/my-app/configs/app.conf.backup
```{{exec}}

### 4.2. Sao chép thư mục đệ quy (`cp -r`)
Khi sao chép thư mục, Linux bắt buộc bạn phải thêm cờ **`-r` (Recursive - Đệ quy)** để sao chép toàn bộ tệp và thư mục con bên trong:

```bash
cp -r /tmp/my-app/src /tmp/my-app/src-backup
```{{exec}}

### 4.3. Di chuyển hoặc Đổi tên (`mv`)
Lệnh `mv` (**Move**) được dùng cho cả 2 mục đích:
- **Đổi tên:** Nếu đường dẫn đích cùng thư mục nhưng tên khác.
- **Di chuyển:** Đưa file/thư mục sang một vị trí mới trên cây thư mục.

```bash
# Đổi tên file
mv /tmp/my-app/configs/app.conf.backup /tmp/my-app/configs/app.conf.old

# Di chuyển file sang thư mục logs
mv /tmp/my-app/configs/app.conf.old /tmp/my-app/logs/
```{{exec}}

---

## 5. Xóa Tệp & Thư Mục An Toàn Với `rm`

- **Xóa file:** `rm <tên-file>`
- **Xóa thư mục rỗng:** `rmdir <tên-thư-mục>`
- **Xóa thư mục có chứa dữ liệu:** `rm -r <tên-thư-mục>`
- **Xóa cưỡng chế không hỏi lại:** `rm -rf <tên-thư-mục>` (kết hợp cờ `-r` đệ quy và `-f` force).

```bash
rm -rf /tmp/my-app/src-backup
```{{exec}}

> ### ⚠️ Cảnh Báo An Toàn Sống Còn Trong Vận Hành Hệ Thống
> Trên Linux Terminal, **KHÔNG CÓ THÙNG RÁC (Recycle Bin)**. Một khi bạn đã chạy lệnh `rm -rf`, dữ liệu sẽ biến mất vĩnh viễn khỏi ổ cứng!
> 
> Một trong những thảm họa kinh điển của kỹ sư là biến số rỗng trong Bash Script:
> ```bash
> # NẾU BIẾN $BACKUP_DIR VÌ LÝ DO NÀO ĐÓ BỊ RỖNG HOẶC CHƯA KHAI BÁO:
> rm -rf $BACKUP_DIR/* 
> # -> Lệnh sẽ trở thành: rm -rf /* (XÓA SẠCH TOÀN BỘ HỆ ĐIỀU HÀNH VÀ MÁY CHỦ!)
> ```
> Luôn kiểm tra kỹ đường dẫn tuyệt đối trước khi bấm Enter với `rm -rf`.

---

## 6. Thử Thách Bước 3: Thiết Kế Cấu Trúc Dự Án DevOps

**Nhiệm vụ của bạn:**
Hãy khởi tạo một không gian làm việc chuẩn cho dự án DevOps tại đường dẫn `/root/devops-workspace/` với cấu trúc chuẩn hóa như sau:

```text
/root/devops-workspace/
├── app/
│   ├── configs/
│   │   └── app.env
│   └── src/
│       └── main.py
├── backups/
│   └── app.env.bak
└── logs/
```

**Các yêu cầu cụ thể cần hoàn thành:**
1. Tạo đầy đủ các thư mục `app/configs`, `app/src`, `backups`, `logs` bên trong `/root/devops-workspace` (khuyến khích dùng `mkdir -p`).
2. Sử dụng lệnh `touch` tạo file rỗng `main.py` trong `app/src/` và file `app.env` trong `app/configs/`.
3. Dùng lệnh `cp` sao chép file `app/configs/app.env` sang thư mục `backups/` với tên mới là `app.env.bak`.
4. Tạo một thư mục rác `temp-scratch/` bên trong `/root/devops-workspace`, tạo một file `test.log` bên trong nó, sau đó dùng lệnh `rm -r` xóa sạch thư mục `temp-scratch` này.
5. Kiểm tra lại kiến trúc vừa tạo bằng lệnh:
   ```bash
   tree /root/devops-workspace
   ```

Sau khi hoàn thành, hãy bấm **Check** để hệ thống tự động đánh giá và chấm điểm cấu trúc dự án của bạn!
