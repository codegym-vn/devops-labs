# Bước 2: Khôi Phục Dữ Liệu Đã Mất Với Git Reflog & Dangling Commits

Một trong những nỗi sợ lớn nhất của lập trình viên là lỡ tay chạy lệnh xóa dữ liệu như `git reset --hard` hoặc xóa nhầm branch (`git branch -D`). Trong bước này, bạn sẽ hiểu vì sao dữ liệu trong Git gần như không bao giờ mất ngay lập tức và cách sử dụng **Git Reflog** để giải cứu mọi commit.

---

## 1. Bản Chất Bất Biến Của Dữ Liệu Trong Git

Tại sao Git có thể cứu được dữ liệu đã bị xóa?
- Mọi Git Object (`commit`, `tree`, `blob`) khi đã được tạo ra thì đều là **bất biến (immutable)** và được lưu trong `.git/objects/`.
- Một nhánh (branch) thực chất chỉ là một file văn bản nhỏ chứa mã SHA-1 trỏ vào một commit.
- Khi bạn xóa branch hoặc reset commit, Git **chỉ xóa hoặc di dời con trỏ**, các commit và file code cũ vẫn còn nguyên vẹn trong Object Database và trở thành **dangling objects** (đối tượng mồ côi).
- Các đối tượng này sẽ tồn tại ít nhất 30 đến 90 ngày trước khi tiến trình dọn rác tự động (`git gc`) dọn dẹp.

---

## 2. Tìm Hiểu Về Git Reflog (Reference Logs)

`reflog` là nhật ký ghi lại mọi chuyển động của con trỏ `HEAD` trên máy cục bộ của bạn. Mỗi khi bạn thực hiện `commit`, `checkout`, `reset`, `rebase`, `merge` hay `cherry-pick`, Git đều tự động ghi lại một dòng trạng thái vào `.git/logs/HEAD`.

Di chuyển vào repository và kiểm tra nhật ký `reflog`:

```bash
cd /root/devops-project && git reflog
```{{exec}}

Đầu ra mẫu:
```text
4a2b1c3 (HEAD -> main) HEAD@{0}: checkout: moving from feature-payment to main
7f8e9d0 HEAD@{1}: commit: feat(payment): implement payment processing module
4a2b1c3 (HEAD -> main) HEAD@{2}: checkout: moving from main to feature-payment
4a2b1c3 (HEAD -> main) HEAD@{3}: commit: chore: add deploy scripts and secret token
1e2d3c4 HEAD@{4}: commit (initial): feat: initial commit with app structure
```

Cú pháp `HEAD@{n}`: Vị trí của con trỏ HEAD cách thời điểm hiện tại `n` bước.

---

## 3. Kịch Bản 1: Khôi Phục Sau Khi `git reset --hard`

Giả sử một thành viên trong nhóm lỡ tay thực hiện lùi commit và xóa sạch working tree:

```bash
git reset --hard HEAD~1
```{{exec}}

Kiểm tra lịch sử bằng `git log --oneline`:

```bash
git log --oneline
```{{exec}}

Commit mới nhất đã hoàn toàn biến mất khỏi `git log`! Nhưng khi xem lại bằng `git reflog`:

```bash
git reflog
```{{exec}}

Dòng đầu tiên cho thấy con trỏ HEAD vừa bị di dời bởi lệnh `reset`. Dòng ngay trước đó (`HEAD@{1}`) chính là commit bạn vừa làm mất!

Khôi phục lại trạng thái ban đầu:

```bash
git reset --hard HEAD@{1}
```{{exec}}

Kiểm tra lại `git log --oneline`:

```bash
git log --oneline
```{{exec}}

Toàn bộ commit và mã nguồn đã được khôi phục nguyên vẹn 100%.

---

## 4. Công Cụ Quét Đối Tượng Mồ Côi (`git fsck`)

Khi không còn nhớ mốc thời gian trong `reflog` (hoặc reflog đã hết hạn), bạn có thể dùng lệnh `git fsck` (File System Consistency Check):

```bash
git fsck --lost-found
```{{exec}}

Lệnh này sẽ quét toàn bộ database và in ra danh sách tất cả các commit và blob mồ côi (`dangling commit <SHA>`, `dangling blob <SHA>`), giúp bạn tìm lại bất kỳ đoạn code nào từng được lưu vào Git.

---

## 5. Thử Thách & Xác Thực (Verification)

Trong quá trình khởi tạo môi trường thực hành ban đầu, một nhánh tính năng cực kỳ quan trọng tên là `feature-payment` đã bị người quản trị xóa nhầm bằng lệnh:
```text
git branch -D feature-payment
```

Mã nguồn xử lý thanh toán `payment.py` hiện không còn xuất hiện trên nhánh `main`. Nhiệm vụ của bạn là sử dụng `git reflog` để giải cứu nhánh này.

### Yêu cầu thử thách:
1. Đứng tại thư mục `/root/devops-project`.
2. Dùng lệnh `git reflog` để tìm mã băm SHA của commit có nội dung:
   ```text
   feat(payment): implement payment processing module
   ```
3. Tái tạo lại nhánh với đúng tên `feature-payment` từ mã commit vừa tìm được:
   ```text
   git branch feature-payment <commit_sha>
   ```
4. Chuyển sang nhánh vừa khôi phục (`git checkout feature-payment`) và kiểm tra file `payment.py` đã xuất hiện trở lại trong thư mục làm việc.

*(Lưu ý: Bạn phải tự nhập lệnh, không có nút chạy tự động cho phần thử thách)*

<details>
<summary>Xem gợi ý các bước thực hiện</summary>

Xem nhật ký reflog để tìm commit của payment:
```bash
git reflog
```

Tìm dòng có thông điệp `feat(payment): implement payment processing module` và lấy mã SHA 7 ký tự đầu dòng (ví dụ: `abc1234`).

Tạo lại branch từ commit đó:
```bash
git branch feature-payment <commit_sha>
```

Chuyển sang branch để xác nhận file:
```bash
git checkout feature-payment
ls -la payment.py
cat payment.py
```

</details>

Sau khi hoàn thành và nhánh `feature-payment` đã có file `payment.py`, hãy bấm nút **Check** bên dưới để hệ thống tự động xác thực!
