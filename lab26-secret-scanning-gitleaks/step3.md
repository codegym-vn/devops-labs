# Bước 3: Cấu Hình Git Pre-commit Hook Chặn Đứng Rò Rỉ Tự Động

Cách phòng thủ tốt nhất là ngăn chặn không cho secret lọt vào Git ngay từ đầu. Trong bước này, bạn sẽ thiết lập **Git Pre-commit Hook** để tự động kích hoạt Gitleaks mỗi khi lập trình viên gõ lệnh `git commit`.

---

## 1. Cơ Chế `gitleaks protect --staged`

Thay vì quét toàn bộ repo mất thời gian, lệnh `gitleaks protect --staged` chỉ tập trung rà soát các thay đổi nằm trong vùng đệm (Staging Area — các file đã chạy `git add`). Nếu phát hiện chuỗi ký tự bí mật, lệnh sẽ trả về mã lỗi và hủy bỏ lệnh commit ngay lập tức.

---

## 2. Các Bước Thực Hiện

### 2.1 — Khởi tạo tệp Pre-commit Hook

Tạo tệp `.git/hooks/pre-commit`:

```bash
cd /root/secret-leak-lab
cat << 'EOF' > .git/hooks/pre-commit
#!/bin/sh
echo "---------------------------------------------------------"
echo "[Gitleaks Hook] Dang kiem tra an ninh truoc khi commit..."
echo "---------------------------------------------------------"

gitleaks protect --staged -v

if [ $? -ne 0 ]; then
  echo ""
  echo "========================================================="
  echo "[TU CHOI] Phat hien thong tin mat hoac token trong code!"
  echo "Vui long go bo secret truoc khi commit len Git."
  echo "========================================================="
  exit 1
fi
EOF

chmod +x .git/hooks/pre-commit
```{{exec}}

---

### 2.2 — Thử nghiệm cơ chế chặn rò rỉ bí mật

Tạo một tệp mới chứa GitHub Personal Access Token (PAT) giả lập:

```bash
cat << 'EOF' > github_sync.js
// Dong bo du lieu voi GitHub API
const GITHUB_TOKEN = "ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
console.log("Connecting with token:", GITHUB_TOKEN);
EOF
```{{exec}}

Đưa tệp vào Staging Area và cố gắng thực hiện commit:

```bash
git add github_sync.js
git commit -m "feat: tich hop dong bo github api"
```{{exec}}

Quan sát thông báo trên màn hình:
* Hook tự động được kích hoạt.
* Gitleaks nhận diện ngay quy tắc `github-pat` với secret `ghp_ABC...`.
* Lệnh commit bị **hủy bỏ hoàn toàn**. Không có commit mới nào được ghi nhận vào Git history.

Kiểm tra lại trạng thái Git:

```bash
git status
```{{exec}}

Tệp `github_sync.js` vẫn nằm ở trạng thái Staged và chưa hề bị ghi vào lịch sử.

Nhấn **Check** để hoàn thành Bước 3!
