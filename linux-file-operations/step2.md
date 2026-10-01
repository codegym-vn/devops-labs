# Bước 2: Sao Chép, Di Chuyển, Đổi Tên & Xóa Tệp/Thư Mục

Trong quản trị hạ tầng, bạn thường xuyên phải thực hiện các thao tác: sao lưu tệp cấu hình trước khi chỉnh sửa, di chuyển các bản ghi dữ liệu vào thư mục lưu trữ, và dọn dẹp các tệp tạm phát sinh sau quá trình build/test.

---

## 1. Làm Chủ Lệnh `cp` (Copy)

Lệnh `cp` dùng để sao chép tệp tin và thư mục từ nguồn sang đích.

Cú pháp:
```text
cp [tùy_chọn] <nguồn> <đích>
```

### Các cờ hiệu quan trọng trong thực tế:
- **`-v` (Verbose):** In chi tiết từng tệp được sao chép lên màn hình, giúp bạn dễ dàng theo dõi tiến trình.
- **`-p` (Preserve):** Giữ nguyên các thuộc tính gốc của tệp (mốc thời gian sửa đổi, quyền hạn). Rất quan trọng khi sao lưu file cấu hình!
- **`-r` (Recursive):** Bắt buộc phải có khi sao chép một **thư mục** chứa dữ liệu, giúp sao chép đệ quy toàn bộ thư mục con và tệp tin bên trong.

### Ví dụ thực hành:
```bash
# Tạo một file mẫu
echo "PORT=8080" > /tmp/sample.conf

# Sao lưu file cấu hình giữ nguyên thuộc tính
cp -pv /tmp/sample.conf /tmp/sample.conf.bak

# Sao chép cả thư mục đệ quy
cp -rv /root/ecommerce-app/src /tmp/src-backup
```{{exec}}

---

## 2. Di Chuyển & Đổi Tên Với `mv` (Move)

Lệnh `mv` đảm nhiệm hai vai trò cơ bản trên hệ điều hành Linux:
1. **Đổi tên tệp / thư mục (Rename):** Khi đường dẫn đích nằm cùng thư mục nhưng mang tên mới.
2. **Di chuyển tệp / thư mục (Move):** Khi đưa tệp sang một vị trí thư mục khác trên hệ thống.

```bash
# 1. Đổi tên tệp
mv /tmp/sample.conf.bak /tmp/sample.conf.old

# 2. Di chuyển tệp vào thư mục khác
mv /tmp/sample.conf.old /tmp/src-backup/

# 3. Vừa di chuyển vừa đổi tên cùng lúc
mv /tmp/sample.conf /tmp/src-backup/main-config.conf
```{{exec}}

---

## 3. Xóa Dữ Liệu An Toàn Với `rm` & `rmdir`

- **`rmdir <thư_mục>`:** Chỉ xóa được các thư mục **hoàn toàn rỗng**. Lệnh này an toàn vì nếu thư mục còn chứa tệp tin, Linux sẽ từ chối xóa và báo lỗi `Directory not empty`.
- **`rm <tệp>`:** Xóa một hoặc nhiều tệp tin thông thường.
- **`rm -r <thư_mục>`:** Xóa đệ quy toàn bộ thư mục và các tệp bên trong.
- **`rm -f` (Force):** Bỏ qua mọi thông báo nhắc nhở xác nhận và không báo lỗi nếu tệp không tồn tại.

> **Cảnh báo sống còn:**
> Khi sử dụng ký tự đại diện wildcard `*` với lệnh `rm` (ví dụ `rm *.tmp`), hãy luôn dùng lệnh `ls *.tmp` trước để xem chính xác những file nào sẽ bị xóa, tránh việc xóa nhầm các tệp tin quan trọng!

---

## 4. Thử Thách Bước 2: Bảo Trì & Tổ Chức Dữ Liệu Ứng Dụng

**Nhiệm vụ của bạn:**
Thực hiện các thao tác quản lý dữ liệu trên dự án `/root/ecommerce-app` đã dựng ở Bước 1:

1. **Sao lưu file cấu hình:**
   Sao chép tệp `configs/app.conf` thành `configs/app.conf.backup` nằm trong cùng thư mục `configs/`.
2. **Tạo thư mục lưu trữ:**
   Tạo một thư mục mới tại đường dẫn: `/root/ecommerce-app/backups`.
3. **Sao lưu toàn bộ mã nguồn đệ quy:**
   Sao chép toàn bộ thư mục `src/` vào vị trí mới `/root/ecommerce-app/backups/src-snapshot/` bằng lệnh `cp -r`.
4. **Tạo các tệp phát sinh thử nghiệm:**
   Đứng tại thư mục `/root/ecommerce-app` và chạy lệnh sau để tạo 3 file thử nghiệm:
   ```bash
   touch /root/ecommerce-app/test1.tmp /root/ecommerce-app/test2.tmp /root/ecommerce-app/app.log.old
   ```
5. **Di chuyển và đổi tên nhật ký:**
   Di chuyển tệp `app.log.old` vào thư mục `logs/` và đổi tên nó thành `old-service.log` (đường dẫn đích: `/root/ecommerce-app/logs/old-service.log`) bằng lệnh `mv`.
6. **Dọn dẹp tệp rác:**
   Sử dụng lệnh `rm` để xóa sạch các tệp có đuôi `.tmp` vừa tạo trong `/root/ecommerce-app`.

Sau khi hoàn tất, hãy nhấn nút **Check** để hệ thống kiểm tra và nghiệm thu kết quả!
