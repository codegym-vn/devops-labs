# Chào Mừng Đến Với Lab 6: Phân Tích Git Internals, Khôi Phục Dữ Liệu Với Reflog & Cấu Hình Git Hooks

Trong quá trình phát triển phần mềm và vận hành CI/CD, Git là công cụ quản lý phiên bản không thể thiếu. Hầu hết các kỹ sư đều quen thuộc với các lệnh bề mặt như `git add`, `git commit`, `git push`. Tuy nhiên, khi gặp các sự cố nghiêm trọng như **lỡ tay xóa nhầm branch**, **reset nhầm commit quan trọng**, hoặc **cần kiểm soát bảo mật mã nguồn trước khi commit**, việc thiếu hiểu biết về bản chất hoạt động bên trong của Git sẽ dẫn đến sự lúng túng hoặc mất mát dữ liệu đáng tiếc.

Bài lab này sẽ đưa bạn đi sâu vào bên trong cơ chế hoạt động của Git (Git Internals) — từ việc khám phá cách Git lưu trữ dữ liệu dưới dạng **Content-Addressable Key-Value Store**, làm chủ công cụ giải cứu dữ liệu **Git Reflog**, cho đến việc tự động hóa kiểm soát chất lượng bằng **Git Hooks**.

---

## Kiến Trúc Hệ Thống Đối Tượng Của Git (Git Object Model)

Mọi trạng thái mã nguồn trong Git đều được lưu trữ dưới dạng đồ thị có hướng không chu trình (DAG - Directed Acyclic Graph) thông qua 4 loại đối tượng cơ bản trong thư mục `.git/objects/`:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                          Git Object Database                           │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│   Commit Object (Metadata, Author, Committer, Parent SHA)              │
│      │                                                                 │
│      ▼ con trỏ tới root tree                                           │
│   Tree Object (Cấu trúc thư mục gốc /)                                 │
│      ├── Tree Object (Thư mục con scripts/)                            │
│      │      └── Blob Object (Nội dung file scripts/deploy.sh)          │
│      ├── Blob Object (Nội dung file README.md)                         │
│      └── Blob Object (Nội dung file app.py)                            │
│                                                                        │
│   Con trỏ nhánh & HEAD:                                                │
│   HEAD ──────► refs/heads/main ──────► [Commit SHA gần nhất]           │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Lộ Trình 3 Bước Thực Hành

| Bước | Chủ Đề | Nội Dung Chi Tiết |
|---|---|---|
| **Bước 1** | **Mổ Xẻ Git Internals** | Khám phá thư mục `.git/`, phân tích 4 loại đối tượng (Blob, Tree, Commit, Tag), sử dụng các plumbing commands (`git cat-file`, `git hash-object`, `git ls-tree`) để truy vết cây dữ liệu. |
| **Bước 2** | **Khôi Phục Dữ Liệu Với Reflog** | Hiểu cơ chế ghi nhật ký di chuyển của con trỏ `HEAD`, phân tích các kịch bản sự cố (`git reset --hard`, xóa nhầm branch) và thực hành phục hồi 100% commit tưởng như đã mất. |
| **Bước 3** | **Tự Động Hóa Với Git Hooks** | Tìm hiểu vòng đời Client-side Git Hooks trong `.git/hooks/`, tự tay viết hook `pre-commit` quét rò rỉ secret và hook `commit-msg` ép chuẩn Conventional Commits. |

---

## Yêu Cầu Môi Trường Thực Hành

- Một repository mẫu đã được chuẩn bị sẵn tại thư mục `/root/devops-project`.
- Toàn bộ các thử thách ở cuối mỗi bước đều theo chuẩn **DIY (Do It Yourself)**: bạn sẽ tự tay thực thi lệnh, phân tích mã băm SHA và viết kịch bản hook mà không có nút chạy tự động.

Nhấn **Start Scenario** để bắt đầu Bước 1!
