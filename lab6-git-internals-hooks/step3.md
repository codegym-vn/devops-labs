# Bước 3: Tự Động Hóa Chất Lượng Code Với Git Hooks (Pre-commit & Commit-msg)

Trong quy trình DevOps hiện đại, nguyên lý **Shift-Left** khuyến khích việc phát hiện và ngăn chặn lỗi hoặc lỗ hổng bảo mật càng sớm càng tốt — ngay tại máy của lập trình viên trước khi mã nguồn được đẩy lên repository từ xa hoặc chạy qua pipeline CI/CD. **Git Hooks** là công cụ đắc lực nhất để hiện thực hóa mục tiêu này.

---

## 1. Nguyên Lý Hoạt Động Của Git Hooks

Git Hooks là các tập lệnh (scripts) tự động được kích hoạt khi có các sự kiện Git cụ thể diễn ra. Chúng nằm tại thư mục:
```text
.git/hooks/
```

Liệt kê các hook mẫu có sẵn trong repository:

```bash
cd /root/devops-project && ls -la .git/hooks/
```{{exec}}

Bạn sẽ thấy các file có đuôi `.sample` (như `pre-commit.sample`, `commit-msg.sample`).
- Để kích hoạt một hook, bạn chỉ cần tạo hoặc đổi tên file bỏ phần mở rộng `.sample` và cấp quyền thực thi: `chmod +x .git/hooks/<tên_hook>`.
- **Quy tắc chặn của Hook**: Nếu script hook kết thúc với mã thoát khác 0 (`exit 1`), Git sẽ **hủy bỏ thao tác** hiện tại ngay lập tức!

---

## 2. Phân Loại Git Hooks

### Client-side Hooks (Chạy trên máy cục bộ của lập trình viên):
- **`pre-commit`**: Chạy ngay khi gõ `git commit`, trước khi commit message được nhập. Phù hợp để lint code, chạy test nhanh hoặc quét secret.
- **`commit-msg`**: Chạy sau khi commit message được nhập. Phù hợp để kiểm tra định dạng thông điệp (Conventional Commits, Ticket ID).
- **`pre-push`**: Chạy trước khi lệnh `git push` thực hiện truyền dữ liệu lên remote.

### Server-side Hooks (Chạy trên máy chủ Git như GitLab/GitHub Enterprise):
- **`pre-receive`**: Chạy khi remote nhận push; có thể từ chối push nếu vi phạm chính sách của tổ chức.
- **`post-receive`**: Chạy sau khi push hoàn tất; thường dùng để kích hoạt Webhook CI/CD.

---

## 3. Xây Dựng Hook `pre-commit` Ngăn Chặn Rò Rỉ Bí Mật (Secret Detection)

Mỗi năm có hàng triệu API keys và token bị rò rỉ công khai lên GitHub do lập trình viên vô tình commit file cấu hình. Một script `pre-commit` hook đơn giản có thể ngăn chặn điều này:

```bash
cat << 'EOF' > /root/devops-project/.git/hooks/pre-commit
#!/bin/bash

# Kiem tra noi dung chuan bi commit
if git diff --cached | grep -qE "PRIVATE_KEY|PASSWORD=|API_TOKEN"; then
    echo "========================================================"
    echo "[SECURITY ERROR] Phat hien thong tin nhay cam trong commit!"
    echo "Qua trinh commit bi huy bo de bao ve bao mat he thong."
    echo "========================================================"
    exit 1
fi

exit 0
EOF

chmod +x /root/devops-project/.git/hooks/pre-commit
```{{exec}}

---

## 4. Xây Dựng Hook `commit-msg` Ép Chuẩn Conventional Commits

Quy ước **Conventional Commits** giúp lịch sử Git rõ ràng và cho phép tự động sinh CHANGELOG cũng như versioning (Semantic Versioning):
- Cú pháp chuẩn: `feat: ...`, `fix: ...`, `docs: ...`, `refactor: ...`, `chore: ...`.

Git tự động truyền đường dẫn file tạm chứa commit message vào tham số đầu tiên của script (`$1`):

```bash
cat << 'EOF' > /root/devops-project/.git/hooks/commit-msg
#!/bin/bash

COMMIT_MSG_FILE="$1"
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Regex kiem tra tien to chuan
PATTERN="^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .+"

if ! echo "$COMMIT_MSG" | grep -qE "$PATTERN"; then
    echo "========================================================"
    echo "[ERROR] Commit message khong dung dinh dang Conventional Commits!"
    echo "Dinh dang yeu cau: <type>(<scope>): <description>"
    echo "Vi du hop le: feat(auth): add login with google"
    echo "========================================================"
    exit 1
fi

exit 0
EOF

chmod +x /root/devops-project/.git/hooks/commit-msg
```{{exec}}

---

## 5. Thử Thách & Xác Thực (Verification)

Hãy tự tay xây dựng một chốt kiểm soát bảo mật (Security Gate) bằng `pre-commit` hook để bảo vệ repository `/root/devops-project`:

### Yêu cầu thử thách:
1. Mở file `.git/hooks/pre-commit` trong thư mục `/root/devops-project`.
2. Viết mã để hook quét qua toàn bộ nội dung staged (`git diff --cached`).
3. Nếu phát hiện chứa chuỗi `AWS_SECRET_KEY=`, hook phải in ra thông báo cảnh báo và thoát với mã lỗi: `exit 1`.
4. Nếu không có vi phạm, hook trả về: `exit 0`.
5. Cấp quyền thực thi cho hook: `chmod +x .git/hooks/pre-commit`.
6. **Tự kiểm thử thực tế**:
   - Tạo file thử nghiệm chứa chuỗi cấm (ví dụ: `echo "AWS_SECRET_KEY=AKIAIOSFODNN7EXAMPLE" > test_secret.txt`).
   - Đưa vào index: `git add test_secret.txt`.
   - Thử commit: `git commit -m "feat: add aws credentials"`.
   - Xác nhận tiến trình commit đã bị hook chặn lại thành công!
   - Gỡ bỏ file vi phạm khỏi index: `git reset HEAD test_secret.txt` và `rm -f test_secret.txt`.

*(Lưu ý: Bạn phải tự nhập lệnh, không có nút chạy tự động cho phần thử thách)*

<details>
<summary>Xem gợi ý mã nguồn hook</summary>

Viết script hook bằng lệnh cat:

```bash
cat << 'EOF' > /root/devops-project/.git/hooks/pre-commit
#!/bin/bash

if git diff --cached | grep -q "AWS_SECRET_KEY="; then
    echo "[BLOCKED] Phat hien AWS_SECRET_KEY! Commit bi tu choi."
    exit 1
fi

exit 0
EOF

chmod +x /root/devops-project/.git/hooks/pre-commit
```

Kiểm tra hoạt động:
```bash
echo "AWS_SECRET_KEY=sample_secret_key_123" > test_secret.txt
git add test_secret.txt
git commit -m "chore: test secret block"
```
*(Kết quả phải in ra thông báo bị chặn và không tạo commit mới).*

Sau đó dọn dẹp file test:
```bash
git reset HEAD test_secret.txt
rm -f test_secret.txt
```

</details>

Sau khi hoàn thành cấu hình hook và thử nghiệm chặn thành công, hãy bấm nút **Check** bên dưới để hệ thống tự động xác thực!
