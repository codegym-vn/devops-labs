# Bước 3: Rebase vs Merge & Quy Trình Duyệt / Squash PR Trên Dòng Lệnh

Trong các dự án chuyên nghiệp, việc giữ cho lịch sử commit rõ ràng, dễ truy vết lỗi (debugging với `git bisect`) là tiêu chuẩn bắt buộc. Trong bước này, bạn sẽ so sánh hai trường phái **Merge vs Rebase**, học cách xử lý xung đột từng bước trong quá trình Rebase và thực hiện kỹ thuật **Squash & Merge** chuẩn công nghiệp.

---

## 1. So Sánh: Git Merge vs Git Rebase

| Đặc Điểm | `git merge` | `git rebase` |
|---|---|---|
| **Cơ chế** | Tạo một "Merge Commit" liên kết 2 nhánh lại với nhau | Nhấc toàn bộ commit của nhánh tính năng, đặt tiếp nối lên đỉnh của `main` |
| **Lịch sử commit** | Lịch sử dạng đồ thị rẽ nhánh song song, lưu đúng thứ tự thời gian | Lịch sử tuyến tính (Linear History) thẳng tắp, không có nhánh con |
| **Commit SHA** | Giữ nguyên SHA của các commit cũ | Tính toán lại SHA mới cho các commit được rebase |
| **Xử lý xung đột** | Giải quyết xung đột 1 lần duy nhất trong merge commit | Giải quyết xung đột từng commit một khi Git áp dụng lại |

### Quy Tắc Vàng Của Rebase (Golden Rule of Rebase)
> **Tuyệt đối không bao giờ Rebase trên các nhánh công khai** (như `main`) mà những người khác đang cùng làm việc. Chỉ Rebase trên nhánh tính năng cá nhân của bạn trước khi tích hợp vào nhánh chính!

---

## 2. Quy Trình Rebase Nhánh Tính Năng Lên Trên `main`

Giả sử nhánh `feature/notification` được tạo từ commit cũ hơn của `main`. Để cập nhật các tính năng mới nhất từ `main` vào nhánh của bạn trước khi mở PR:

Chuyển sang nhánh tính năng:

```bash
cd /root/devops-app && git checkout feature/notification
```{{exec}}

Kiểm tra sự khác biệt commit giữa 2 nhánh:

```bash
git log --oneline --graph main feature/notification -n 6
```{{exec}}

Bắt đầu tiến trình Rebase:

```bash
git rebase main
```{{exec}}

Git sẽ tua lại và áp dụng lại commit của bạn lên đỉnh mới nhất của `main`.

---

## 3. Xử Lý Xung Đột Trong Quá Trình Rebase

Khi Rebase gặp xung đột, Git sẽ tạm dừng tại đúng commit bị lỗi và hiển thị trạng thái:
```text
(feature/notification|REBASE 1/1)
```

### 3 bước xử lý xung đột trong Rebase:
1. Mở file bị conflict và sửa thủ công các đoạn mã.
2. Đánh dấu file đã sửa bằng lệnh: `git add <file>`.
3. Tiếp tục tiến trình Rebase bằng lệnh:
   ```bash
   git rebase --continue
   ```
   *(Lưu ý: TUYỆT ĐỐI KHÔNG chạy `git commit` khi đang ở trạng thái rebase).*
4. Nếu muốn hủy bỏ và quay lại trạng thái ban đầu: `git rebase --abort`.

---

## 4. Kỹ Thuật Review & Squash PR Chuẩn Công Nghiệp

Khi phát triển một tính năng, lập trình viên có thể tạo ra hàng chục commit nháp (như `fix typo`, `wip`, `test debug`). Nếu merge tất cả vào `main`, lịch sử dự án sẽ rất rối.

Kỹ thuật **Squash & Merge** cho phép gộp toàn bộ thay đổi thành đúng **1 commit duy nhất** đại diện cho toàn bộ tính năng:

```bash
# Chuyen ve main
git checkout main

# Merge squash (gom toan bo code vao Staging Area ma chua commit)
git merge --squash feature/notification

# Tao commit tong the voi message chuan Conventional Commits
git commit -m "feat(notify): integrate notification service into application"
```

---

## 5. Thử Thách & Xác Thực (Verification)

Hãy tự tay thực hiện toàn bộ quy trình: Rebase nhánh tính năng, giải quyết xung đột rebase và thực hiện Squash & Merge vào `main`.

### Yêu cầu thử thách:
1. Đứng tại `/root/devops-app`, chuyển sang nhánh `feature/notification`.
2. Chạy lệnh:
   ```bash
   git rebase main
   ```
3. Do `main` đã có nhiều thay đổi ở Bước 2, file `app.py` sẽ phát sinh xung đột:
   - Mở file `app.py`, giữ nguyên toàn bộ logic hiện tại của `main` (bao gồm `get_config`, `process_data`, `process_payment`).
   - Đưa hàm `send_notification` vào cuối file `app.py`:
     ```python
     def send_notification(msg):
         print("Sending notification: " + str(msg))
         return True
     ```
   - Xóa sạch toàn bộ các ký hiệu đánh dấu xung đột (`<<<<<<<`, `|||||||`, `=======`, `>>>>>>>`).
4. Đánh dấu đã sửa bằng `git add app.py` và tiếp tục rebase:
   ```bash
   git rebase --continue
   ```
5. Chuyển về nhánh `main` (`git checkout main`).
6. Thực hiện **Squash & Merge** nhánh `feature/notification` vào `main`:
   ```bash
   git merge --squash feature/notification
   git commit -m "feat(notify): add notification system to microservice"
   ```
7. Đẩy commit mới nhất lên Central Server:
   ```bash
   git push origin main
   ```
8. Dùng lệnh `git log -n 3 --oneline` để xác nhận commit squash đã nằm trên đỉnh `main` một cách gọn gàng.

*(Lưu ý: Bạn phải tự nhập lệnh, không có nút chạy tự động cho phần thử thách)*

<details>
<summary>Xem gợi ý các bước thực hiện</summary>

Chuyển sang nhánh notification và rebase:
```bash
git checkout feature/notification
git rebase main
```

File `app.py` bị xung đột. Chỉnh sửa nội dung file `app.py` hoàn chỉnh:
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

def send_notification(msg):
    print("Sending notification: " + str(msg))
    return True
```

Đánh dấu và tiếp tục rebase:
```bash
git add app.py
git rebase --continue
```

Chuyển về main và thực hiện Squash Merge:
```bash
git checkout main
git merge --squash feature/notification
git commit -m "feat(notify): add notification system to microservice"
git push origin main
```

Kiểm tra lịch sử commit:
```bash
git log -n 3 --oneline
```

</details>

Sau khi hoàn thành và đẩy nhánh `main` lên thành công, hãy bấm nút **Check** bên dưới để hệ thống tự động xác thực!
