# Bước 2: Giải Quyết Xung Đột Hợp Nhất Phức Tạp (3-Way Merge & zdiff3)

Trong làm việc nhóm, xung đột (Merge Conflict) xảy ra khi hai nhánh cùng sửa đổi cùng một dòng code hoặc cùng một khối cấu hình kể từ điểm rẽ nhánh chung. Trong bước này, bạn sẽ làm chủ kỹ thuật giải quyết xung đột đa file bằng **3-Way Merge** và cấu hình hiển thị nâng cao **`zdiff3`**.

---

## 1. Kích Hoạt Chế Độ Hiển Thị Xung Đột Nâng Cao: `zdiff3`

Theo mặc định, khi xảy ra xung đột, Git chỉ hiển thị 2 khối: code hiện tại của bạn (`HEAD`) và code của người khác. Bạn không thể biết code nguyên thủy ban đầu ra sao, dẫn đến việc phán đoán sai ý đồ của đồng nghiệp.

Cấu hình `zdiff3` (Zealous Diff3) bổ sung thêm khối **code gốc (base)** vào giữa:

```bash
git config --global merge.conflictstyle zdiff3
```{{exec}}

Cấu trúc xung đột khi dùng `zdiff3`:
```text
<<<<<<< HEAD (Phiên bản trên nhánh hiện tại của bạn)
port: 8080
timeout: 30
||||||| base (Phiên bản gốc ban đầu trước khi cả hai bên sửa)
port: 8000
=======
port: 9000
payment_gateway: stripe
>>>>>>> origin/feature/payment (Phiên bản của nhánh đang merge vào)
```

Nhìn vào đây, bạn thấy ngay:
- Code gốc có cổng `8000`.
- Nhánh `HEAD` đã đổi cổng thành `8080` và bổ sung `timeout: 30`.
- Nhánh `feature/payment` đã bổ sung `payment_gateway: stripe`.
- **Cách dung hòa chuẩn xác**: Giữ cổng `8080`, giữ cả `timeout: 30` và giữ cả `payment_gateway: stripe`!

---

## 2. Kích Hoạt Xung Đột Thực Tế

Đảm bảo bạn đang ở nhánh `main`:

```bash
cd /root/devops-app && git checkout main
```{{exec}}

Tiến hành merge nhánh `origin/feature/payment` vào `main`:

```bash
git merge origin/feature/payment
```{{exec}}

Git sẽ dừng lại và thông báo xung đột ở cả hai file:
```text
Auto-merging app.py
CONFLICT (content): Merge conflict in app.py
Auto-merging config.yaml
CONFLICT (content): Merge conflict in config.yaml
Automatic merge failed; fix conflicts and then commit the result.
```

Kiểm tra trạng thái bằng `git status`:

```bash
git status
```{{exec}}

Bạn sẽ thấy cả hai file đều ở trạng thái `both modified`. Nhánh hiện tại chuyển sang trạng thái `main|MERGING`.

> **Mẹo khẩn cấp:** Nếu bạn lúng túng hoặc chưa sẵn sàng giải quyết, bạn luôn có thể quay lại trạng thái sạch ban đầu bằng lệnh:
> `git merge --abort`

---

## 3. Quy Trình 4 Bước Giải Quyết Xung Đột

1. **Nhận diện file lỗi**: Dùng `git status` để xem danh sách các file đang bị `both modified`.
2. **Mở file và chỉnh sửa thủ công**: Xóa các thẻ `<<<<<<<`, `|||||||`, `=======`, `>>>>>>>` và kết hợp các đoạn mã hợp lý.
3. **Đánh dấu đã xử lý**: Chạy `git add <file>` cho từng file đã sửa xong.
4. **Tạo Merge Commit**: Khi toàn bộ file đã được `git add`, chạy lệnh `git commit` (hoặc `git merge --continue`) để hoàn tất.

---

## 4. Thử Thách & Xác Thực (Verification)

Hãy tự tay giải quyết triệt để xung đột ở cả 2 file `config.yaml` và `app.py`, sau đó hoàn tất merge commit.

### Yêu cầu thử thách:
1. Đứng tại `/root/devops-app` trên nhánh `main`.
2. Chỉnh sửa file `config.yaml`:
   - Giữ cổng `port: 8080` và `debug: true`.
   - Giữ cấu hình `timeout: 30` trong block `database`.
   - Giữ cấu hình `payment_gateway: stripe` trong block `app`.
   - Xóa bỏ toàn bộ các ký hiệu đánh dấu xung đột (`<<<<<<<`, `|||||||`, `=======`, `>>>>>>>`).
3. Chỉnh sửa file `app.py`:
   - Hàm `get_config()` phải trả về cả `"env": "production"` và `"payment": "enabled"`.
   - Giữ nguyên hàm `process_data()` và hàm mới `process_payment()`.
   - Xóa bỏ toàn bộ các ký hiệu đánh dấu xung đột.
4. Chạy lệnh `git add config.yaml app.py` để đánh dấu đã xử lý.
5. Tạo merge commit bằng lệnh:
   ```bash
   git commit -m "merge: resolve conflicts between main and feature/payment"
   ```
6. Đẩy kết quả đã xử lý lên server:
   ```bash
   git push origin main
   ```

*(Lưu ý: Bạn phải tự nhập lệnh, không có nút chạy tự động cho phần thử thách)*

<details>
<summary>Xem gợi ý nội dung file sau khi giải quyết</summary>

File `config.yaml` hoàn chỉnh:
```yaml
app:
  name: devops-platform
  port: 8080
  debug: true
  payment_gateway: stripe
database:
  host: localhost
  port: 5432
  timeout: 30
```

File `app.py` hoàn chỉnh:
```python
def get_config():
    return {"service": "running", "env": "production", "payment": "enabled"}

def process_data(data):
    print("Validating and processing: " + str(data))
    return True

def process_payment(amount):
    print("Charging: " + str(amount))
    return True

if __name__ == "__main__":
    print("Application started.")
```

Lệnh hoàn tất và push:
```bash
git add config.yaml app.py
git commit -m "merge: resolve conflicts between main and feature/payment"
git push origin main
```

</details>

Sau khi hoàn tất và đẩy lên nhánh `main` thành công, hãy bấm nút **Check** bên dưới để hệ thống tự động xác thực!
