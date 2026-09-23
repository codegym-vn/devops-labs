# Chào Mừng Đến Với Lab 7: Chiến Lược Nhánh, Giải Quyết Xung Đột Phức Tạp & Xử Lý Pull Request

Trong thực tế phát triển phần mềm và vận hành CI/CD, ít khi một kỹ sư làm việc đơn độc trên một kho mã nguồn. Khi nhiều thành viên trong nhóm cùng phát triển các tính năng song song, việc va chạm mã nguồn và phát sinh **xung đột hợp nhất (Merge Conflicts)** là một phần tất yếu của công việc.

Bài lab này được thiết kế để rèn luyện cho bạn phản xạ và kỹ năng xử lý xung đột ở cấp độ chuyên nghiệp: từ việc thấu hiểu mô hình phân nhánh và cơ chế **Pull Request (PR)**, làm chủ kỹ thuật giải quyết xung đột đa file bằng **3-Way Merge & zdiff3**, cho đến việc lựa chọn chính xác giữa **Merge** và **Rebase** để duy trì lịch sử dự án sạch sẽ, chuẩn mực.

---

## Kiến Trúc Môi Trường Mô Phỏng Remote Central Server

Để tạo trải nghiệm thực chiến như khi làm việc với GitHub hay GitLab mà vẫn đảm bảo tốc độ tức thì trên Killercoda, môi trường lab được thiết lập gồm hai thành phần:

```text
┌────────────────────────────────────────────────────────────────────────┐
│               Central Git Server (/srv/git/central-repo.git)          │
│                      [Bare Repository - Kho nguồn trung tâm]           │
│                                                                        │
│   ├── main                  (Nhánh chính đã có commit từ đồng nghiệp)  │
│   ├── feature/payment       (Nhánh tính năng thanh toán đang xung đột) │
│   └── feature/notification  (Nhánh tính năng thông báo)               │
└──────────────────────────────────▲─────────────────────────────────────┘
                                   │ git push / git fetch
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│               Local Developer Workspace (/root/devops-app)             │
│                      [Working Repository của bạn]                      │
│                                                                        │
│   ├── Remote Tracking Branches: origin/main, origin/feature/*          │
│   └── Local Branches: main, feature/auth (sẽ tạo mới ở Bước 1)        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Lộ Trình 3 Bước Thực Hành

| Bước | Chủ Đề | Nội Dung Chi Tiết |
|---|---|---|
| **Bước 1** | **Chiến Lược Nhánh & Khởi Tạo PR** | Hiểu mối quan hệ giữa Local, Remote Tracking và Remote Server; thực hành tạo feature branch, push lên server và review PR bằng cú pháp so sánh `git diff origin/main...origin/feature`. |
| **Bước 2** | **Giải Quyết Xung Đột Phức Tạp** | Mô phỏng tình huống va chạm đa file (`app.py` và `config.yaml`), bật chế độ xem nâng cao `zdiff3` (hiển thị cả base commit gốc), phân tích và dung hòa mã nguồn an toàn. |
| **Bước 3** | **Rebase vs Merge & Squash PR** | Phân biệt triết lý Merge Commit và Linear History (Rebase), xử lý xung đột từng bước trong quá trình rebase (`--continue`), thực hiện kỹ thuật **Squash & Merge** chuẩn công nghiệp. |

---

## Yêu Cầu Môi Trường Thực Hành

- Thư mục làm việc của bạn nằm tại: `/root/devops-app`.
- Thư mục Central Remote Server nằm tại: `/srv/git/central-repo.git`.
- Toàn bộ các thử thách ở cuối mỗi bước đều theo chuẩn **DIY (Do It Yourself)**: học viên tự thao tác và gõ lệnh để giải quyết xung đột mà không có nút chạy tự động.

Nhấn **Start Scenario** để bắt đầu Bước 1!
