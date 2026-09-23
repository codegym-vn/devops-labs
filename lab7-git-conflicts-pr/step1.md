# Bước 1: Chiến Lược Nhánh & Khởi Tạo Quy Trình Pull Request Trên CLI

Trong bước đầu tiên, bạn sẽ tìm hiểu cơ chế kết nối giữa kho cục bộ (Local Repository) và kho từ xa (Remote Server), phân tích các nhánh theo dõi từ xa (Remote Tracking Branches) và thực hành quy trình mở một Pull Request (PR) hoàn toàn bằng các lệnh dòng lệnh.

---

## 1. Khám Phá Remote & Remote Tracking Branches

Di chuyển vào repository làm việc:

```bash
cd /root/devops-app
```{{exec}}

Kiểm tra cấu hình remote server:

```bash
git remote -v
```{{exec}}

Đầu ra cho thấy remote tên `origin` đang trỏ tới kho trung tâm `/srv/git/central-repo.git`.

Liệt kê toàn bộ các nhánh hiện có trong hệ thống (cả local và remote):

```bash
git branch -a
```{{exec}}

Đầu ra mẫu:
```text
* main
  remotes/origin/main
  remotes/origin/feature/notification
  remotes/origin/feature/payment
```

### Phân biệt các loại nhánh:
- **Local Branch (`main`)**: Nhánh nằm trên máy làm việc của bạn, nơi bạn trực tiếp chỉnh sửa và commit code.
- **Remote Tracking Branch (`remotes/origin/main`)**: Bản sao lưu trữ trạng thái con trỏ của remote server tại lần đồng bộ gần nhất. Bạn không thể commit trực tiếp vào nhánh này.
- **Remote Branch (trên Central Server)**: Nhánh thực tế nằm trên máy chủ từ xa. Lệnh `git fetch` sẽ cập nhật các con trỏ Remote Tracking này.

---

## 2. Chiến Lược Phân Nhánh Trong Vận Hành DevOps

Trong môi trường chuyên nghiệp, có hai mô hình phân nhánh phổ biến nhất:

| Mô Hình | Cách Hoạt Động | Ưu Điểm | Khi Nào Dùng |
|---|---|---|---|
| **Git Flow** | Có nhiều nhánh cố định: `main` (production), `develop` (staging), `release/*`, `feature/*`, `hotfix/*` | Kiểm soát chặt chẽ quy trình phát hành theo chu kỳ | Dự án phần mềm đóng gói truyền thống, phát hành theo quý/tháng |
| **Trunk-Based Development** | Chỉ có 1 nhánh chính `main` (trunk), các nhánh `feature/*` sống rất ngắn (vài giờ đến 1-2 ngày) và merge liên tục qua PR | Tránh tích tụ xung đột lớn, triển khai liên tục (CI/CD) | Các hệ thống Cloud Native, Microservices, SaaS phát hành nhiều lần/ngày |

Bài lab này áp dụng mô hình **Trunk-Based Development**: mọi tính năng đều bắt đầu từ `main`, phát triển trên nhánh ngắn và hợp nhất trở lại `main` thông qua Pull Request.

---

## 3. Cách Hệ Thống Review Pull Request Trên Dòng Lệnh

Một **Pull Request (PR)** hoặc **Merge Request (MR)** bản chất là một yêu cầu hợp nhất các commit của một nhánh tính năng vào nhánh chính.

Trước khi đồng ý merge một PR, kỹ sư DevOps thường dùng 2 lệnh sau để review:

### 1. Xem danh sách các commit thuộc về PR (Cú pháp `A..B`):
```bash
git log origin/main..origin/feature/payment --oneline
```{{exec}}

Lệnh trên liệt kê tất cả các commit có trong `feature/payment` nhưng chưa có trong `main`.

### 2. So sánh toàn bộ mã nguồn thay đổi của PR (Cú pháp `A...B` 3 dấu chấm):
```bash
git diff origin/main...origin/feature/payment
```{{exec}}

Cú pháp 3 dấu chấm (`...`) so sánh từ điểm rẽ nhánh chung (Merge Base) đến đỉnh của nhánh tính năng. Đây chính là cách tab "Files Changed" của GitHub và GitLab hiển thị!

---

## 4. Thử Thách & Xác Thực (Verification)

Bạn được giao nhiệm vụ xây dựng tính năng xác thực token người dùng trên một nhánh mới.

### Yêu cầu thử thách:
1. Đứng tại thư mục `/root/devops-app`.
2. Tạo và chuyển sang nhánh mới tên là `feature/auth` từ `main`.
3. Mở file `app.py`, thêm hàm `verify_token` vào cuối file:
   ```python
   def verify_token(token):
       return token == "valid_token_secret_123"
   ```
4. Đưa file vào staging và commit với thông điệp:
   ```text
   feat(auth): implement token verification function
   ```
5. Đẩy nhánh này lên Central Server và thiết lập upstream tracking:
   ```bash
   git push -u origin feature/auth
   ```
6. Tự kiểm tra bằng lệnh `git branch -r` để thấy `origin/feature/auth` đã xuất hiện trên server.

*(Lưu ý: Bạn phải tự nhập lệnh, không có nút chạy tự động cho phần thử thách)*

<details>
<summary>Xem gợi ý các bước thực hiện</summary>

Tạo và checkout sang nhánh mới:
```bash
git checkout -b feature/auth
```

Bổ sung hàm vào cuối file `app.py`:
```bash
cat << 'EOF' >> app.py

def verify_token(token):
    return token == "valid_token_secret_123"
EOF
```

Commit và push:
```bash
git add app.py
git commit -m "feat(auth): implement token verification function"
git push -u origin feature/auth
```

Kiểm tra nhánh đã có trên remote:
```bash
git branch -r
```

</details>

Sau khi hoàn thành và đẩy nhánh lên thành công, hãy bấm nút **Check** bên dưới để hệ thống tự động xác thực!
