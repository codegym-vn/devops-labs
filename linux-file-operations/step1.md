# Bước 1: Khởi Tạo Tệp & Cấu Trúc Thư Mục Đa Tầng

Khi khởi tạo một dịch vụ mới hoặc viết script tự động hóa, việc xây dựng cấu trúc thư mục phân tầng rõ ràng giúp tổ chức mã nguồn, file cấu hình và nhật ký vận hành một cách khoa học.

---

## 1. Khởi Tạo Thư Mục Với `mkdir` & Cờ `-p`

Lệnh `mkdir` (**Make Directory**) dùng để tạo một thư mục mới:

```bash
mkdir demo-folder
```

Tuy nhiên, nếu bạn cố gắng tạo một đường dẫn có nhiều cấp lồng nhau mà các thư mục cha chưa tồn tại:

```bash
mkdir demo-project/backend/api
```
Hệ điều hành sẽ trả về lỗi: `mkdir: cannot create directory ‘demo-project/backend/api’: No such file or directory`.

### Giải pháp: Cờ `-p` (Parents)
Cờ `-p` mang lại 2 lợi ích sống còn cho kỹ sư DevOps:
1. **Tự động tạo tất cả các thư mục cha trung gian** dọc theo đường dẫn nếu chúng chưa có.
2. **Không báo lỗi** nếu thư mục đích đã tồn tại từ trước (tính chất Idempotent rất quan trọng khi chạy lặp lại các pipeline tự động).

```bash
mkdir -p demo-project/backend/api
```{{exec}}

---

## 2. Kỹ Thuật Brace Expansion Của Bash

Thay vì phải gõ nhiều lệnh `mkdir` riêng lẻ, bạn có thể tận dụng cú pháp mở rộng dấu ngoặc nhọn `{...}` của Bash Shell để tạo hàng loạt thư mục cùng lúc:

```bash
mkdir -p demo-project/{src,configs,logs,tests}
ls -l demo-project
```{{exec}}

Bạn thậm chí có thể lồng các nhánh thư mục con:

```bash
mkdir -p demo-project/src/{controllers,models,routes}
tree demo-project
```{{exec}}

---

## 3. Các Phương Pháp Tạo Tệp Tin

### 3.1. Lệnh `touch`
Dùng để tạo nhanh một hoặc nhiều tệp tin rỗng:

```bash
touch demo-project/src/controllers/userController.js
touch demo-project/src/models/userModel.js
```{{exec}}

> **Lưu ý kỹ thuật:** Nếu tệp đã tồn tại, lệnh `touch` sẽ không làm thay đổi nội dung bên trong mà chỉ cập nhật lại mốc thời gian sửa đổi gần nhất (timestamp mtime).

### 3.2. Toán tử chuyển hướng `>` và `>>`
- **`>` (Ghi đè - Overwrite):** Tạo tệp mới và ghi nội dung vào, hoặc xóa sạch nội dung cũ nếu tệp đã tồn tại.
- **`>>` (Nối tiếp - Append):** Ghi thêm dòng mới vào cuối tệp mà không làm mất dữ liệu cũ.

```bash
echo "APP_ENV=production" > demo-project/configs/app.env
echo "APP_PORT=8080" >> demo-project/configs/app.env
cat demo-project/configs/app.env
```{{exec}}

### 3.3. Kỹ thuật Here-Doc (`cat << 'EOF'`)
Trong tự động hóa, khi cần tạo một tệp cấu hình dài nhiều dòng, phương pháp Here-Doc là sự lựa chọn chuẩn mực:

```bash
cat << 'EOF' > demo-project/configs/database.json
{
  "host": "localhost",
  "port": 5432,
  "database": "production_db"
}
EOF
```{{exec}}

---

## 4. Thử Thách Bước 1: Dựng Cây Thư Mục Ứng Dụng Thương Mại Điện Tử

**Nhiệm vụ của bạn:**
Hãy khởi tạo một cây thư mục dự án tại đường dẫn `/root/ecommerce-app` theo đúng cấu trúc tiêu chuẩn dưới đây:

```text
/root/ecommerce-app/
├── configs/
│   └── app.conf
├── logs/
├── src/
│   ├── api/
│   │   └── server.js
│   └── models/
│       └── user.js
└── tests/
```

**Các yêu cầu cụ thể cần hoàn thành:**
1. Tạo các thư mục: `configs`, `logs`, `src/api`, `src/models`, `tests` bên trong `/root/ecommerce-app`.
2. Tạo tệp rỗng `src/models/user.js` bằng lệnh `touch`.
3. Tạo tệp `src/api/server.js` có chứa dòng nội dung `console.log("Server starting...");`.
4. Tạo tệp `configs/app.conf` có chứa dòng nội dung `PORT=3000`.
5. Sử dụng lệnh `tree /root/ecommerce-app` để kiểm tra trực quan cây thư mục của bạn.

Sau khi hoàn thành, hãy nhấn nút **Check** để hệ thống tự động kiểm tra kết quả!
