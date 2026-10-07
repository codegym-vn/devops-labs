# Bước 4: Quản Trị Ngoại Lệ Với .gitleaks.toml & Quy Tắc Tùy Chỉnh

Trong các dự án phát triển phần mềm, bạn sẽ thường xuyên gặp các chuỗi token giả lập (mock tokens), khóa kiểm thử (dummy keys) trong các tệp unit test (`tests/mock_data.json`). Nếu không có cơ chế quản trị ngoại lệ hợp lệ, các công cụ bảo mật sẽ liên tục báo động giả (False Positives).

Gitleaks hỗ trợ tệp cấu hình **`.gitleaks.toml`** để tùy biến quy tắc quét và định nghĩa danh sách miễn trừ (Allowlist).

---

## 1. Cấu Trúc Của Tệp `.gitleaks.toml`

Khối `[allowlist]` trong `.gitleaks.toml` cho phép bỏ qua:
* **paths:** Các đường dẫn tệp tin hoặc thư mục được phép chứa chuỗi mẫu (ví dụ các tệp test).
* **regexes:** Các biểu thức chính quy của token giả định.
* **stopwords:** Các từ khóa đặc biệt không cần quét.

---

## 2. Các Bước Thực Hiện

### 2.1 — Tạo tệp cấu hình `.gitleaks.toml`

Tạo tệp `.gitleaks.toml` tại gốc dự án để bỏ qua tệp mô phỏng `github_sync.js`:

```bash
cd /root/secret-leak-lab
cat << 'EOF' > .gitleaks.toml
title = "Gitleaks Custom Configuration"

[allowlist]
description = "Cho phep mock token trong tep test va mo phong"
paths = [
  '''github_sync\.js'''
]
EOF
```{{exec}}

---

### 2.2 — Cập nhật Hook để tự động nhận diện cấu hình tùy chỉnh

Cập nhật lại tệp `.git/hooks/pre-commit` để nạp tệp cấu hình `.gitleaks.toml`:

```bash
cat << 'EOF' > .git/hooks/pre-commit
#!/bin/sh
gitleaks protect --staged -v --config .gitleaks.toml
if [ $? -ne 0 ]; then
  echo "[TU CHOI] Phat hien thong tin mat! Vui long kiem tra lai."
  exit 1
fi
EOF

chmod +x .git/hooks/pre-commit
```{{exec}}

---

### 2.3 — Thử nghiệm commit lại tệp đã được đưa vào danh sách ngoại lệ

Thực hiện commit lại tệp `github_sync.js` cùng tệp cấu hình `.gitleaks.toml`:

```bash
git add .gitleaks.toml github_sync.js
git commit -m "feat: tich hop dong bo github api kem allowlist hop le"
```{{exec}}

Quan sát kết quả:
* Gitleaks kiểm tra vùng Staging.
* Nhận diện tệp `github_sync.js` nằm trong danh sách `allowlist.paths`.
* Lệnh commit được phê duyệt thành công mà không gặp cảnh báo lỗi!

Kiểm tra lịch sử commit mới:

```bash
git log -n 1 --oneline
```{{exec}}

Commit mới đã xuất hiện hợp lệ trong Git history.

Nhấn **Check** để hoàn thành Bước 4!
