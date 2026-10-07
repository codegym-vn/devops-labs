# Lab 26: Tự Động Quét Lộ Mật Khẩu, Token & Khóa Bí Mật Trong Mã Nguồn Với Gitleaks

Theo báo cáo bảo mật hàng năm của GitHub và GitGuardian, có hàng triệu thông tin xác thực bí mật (Secrets, API keys, Private keys, Database Passwords) bị vô tình commit lên các kho lưu trữ mã nguồn mỗi năm.

Một sự cố rò rỉ secret lên Git có thể gây ra hậu quả thảm khốc:
* Hacker sử dụng bot tự động quét GitHub chỉ mất từ **vài giây đến vài phút** để thu thập API key bị lộ.
* Toàn bộ dữ liệu cơ sở dữ liệu có thể bị mã hóa tống tiền hoặc tài khoản đám mây AWS bị chiếm dụng để đào tiền ảo (Crypto-mining) với chi phí lên đến hàng chục nghìn USD.
* **Đặc tính nguy hiểm của Git:** Dù bạn có tạo một commit mới để xóa file chứa mật khẩu, mật khẩu đó **vẫn tồn tại vĩnh viễn trong lịch sử Git commit (git history)** và bất kỳ ai clone repo đều có thể trích xuất ra được.

---

## 1. Giới Thiệu Công Cụ Gitleaks

**Gitleaks** là công cụ phân tích tĩnh mã nguồn mở hàng đầu thế giới chuyên dùng để phát hiện và ngăn ngừa việc rò rỉ thông tin mật:

```
                  ┌──────────────────────────────────────────────┐
                  │                 GITLEAKS                     │
                  │   (Regex Rules + Shannon Entropy Analysis)   │
                  └──────────────────────┬───────────────────────┘
                                         │
        ┌────────────────────────────────┼────────────────────────────────┐
        ▼                                ▼                                ▼
┌──────────────┐                 ┌──────────────┐                 ┌──────────────┐
│  MÁY NỘI BỘ  │                 │  PRE-COMMIT  │                 │ CI/CD SERVER │
│ Quét thư mục │                 │ Chặn commit  │                 │ Chặn PR merge│
│  hiện tại    │                 │  chứa secret │                 │ vào main     │
└──────────────┘                 └──────────────┘                 └──────────────┘
```

* **Cơ chế nhận diện:** Kết hợp giữa hàng trăm mẫu biểu thức chính quy (Regex) của hơn 160 nhà cung cấp (AWS, Google Cloud, GitHub, Slack, Stripe, JWT...) và thuật toán đo độ hỗn loạn thông tin (Shannon Entropy) để phân biệt chuỗi ngẫu nhiên có độ nguy hiểm cao.
* **Đa chế độ:** Quét thư mục chưa commit (`--no-git`), quét toàn bộ lịch sử commit, chạy làm Git Hook trên máy lập trình viên, hoặc tích hợp trong CI/CD pipeline.

---

## 2. Mục Tiêu Bạn Cần Đạt Được Trong Bài Lab Này

* Sử dụng Gitleaks CLI để phát hiện các secret đang bị lộ trong mã nguồn.
* Quét và truy vết các thông tin mật đã bị chôn sâu trong lịch sử Git commit.
* Thiết lập `pre-commit hook` tự động chặn đứng lập trình viên khi vô tình commit mật khẩu.
* Quản trị các cảnh báo giả (False Positives) một cách an toàn bằng `.gitleaksignore` và tệp cấu hình `.gitleaks.toml`.

Nhấn **Next** để bắt đầu bước đầu tiên!
