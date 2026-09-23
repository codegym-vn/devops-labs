# Bước 1: Mổ Xẻ Git Internals: Blob, Tree, Commit & Content-Addressable Storage

Trong bước đầu tiên, bạn sẽ khám phá cấu trúc lưu trữ bên trong của Git tại thư mục `.git/` và sử dụng các lệnh hệ thống tầng thấp (Plumbing Commands) để giải mã cách Git liên kết các đối tượng bằng mã băm SHA-1.

---

## 1. Khám Phá Thư Mục `.git/`

Di chuyển vào repository mẫu đã được chuẩn bị sẵn:

```bash
cd /root/devops-project
```{{exec}}

Liệt kê cấu trúc các thư mục và tập tin bên trong `.git/`:

```bash
ls -la .git/
```{{exec}}

Các thành phần cốt lõi:
- **`HEAD`**: Tệp tin văn bản chứa con trỏ trỏ tới nhánh làm việc hiện tại (ví dụ: `ref: refs/heads/main`).
- **`refs/heads/`**: Chứa các file đại diện cho từng nhánh cục bộ. Mỗi file chứa đúng 40 ký tự SHA-1 trỏ tới commit mới nhất của nhánh đó.
- **`objects/`**: Cơ sở dữ liệu đối tượng dạng Key-Value (Content-Addressable Storage). Key là mã băm SHA-1 40 ký tự (2 ký tự đầu làm tên thư mục con, 38 ký tự còn lại làm tên file).
- **`index`**: Vùng đệm nhị phân (Staging Area), theo dõi các thay đổi chuẩn bị commit.

Kiểm tra nội dung con trỏ `HEAD`:

```bash
cat .git/HEAD
```{{exec}}

Kiểm tra mã SHA mà nhánh `main` đang trỏ tới:

```bash
cat .git/refs/heads/main
```{{exec}}

---

## 2. Bốn Loại Git Objects Cơ Bản

Mọi dữ liệu trong Git đều thuộc 1 trong 4 loại đối tượng:

| Kiểu Đối Tượng | Chức Năng | Nội Dung Lưu Trữ |
|---|---|---|
| **`blob`** | Binary Large Object | Lưu nội dung tệp tin thuần túy đã nén (không lưu tên file, quyền thực thi) |
| **`tree`** | Directory | Đại diện cho thư mục: liên kết tên file, permissions với mã SHA của blob hoặc tree con |
| **`commit`** | Snapshot Metadata | Chứa con trỏ tới Root Tree, commit cha (parent), tác giả, thời gian và thông điệp commit |
| **`tag`** | Annotated Tag | Con trỏ cố định tới một commit kèm chữ ký, tagger và ghi chú phiên bản |

---

## 3. Các Lệnh Plumbing Để Giải Mã Đối Tượng

Trong Git, các lệnh hàng ngày như `add`, `commit`, `status` được gọi là **Porcelain Commands** (giao diện người dùng). Các lệnh tầng thấp thao tác trực tiếp với object database được gọi là **Plumbing Commands**:

| Lệnh Plumbing | Mục Đích |
|---|---|
| `git rev-parse <ref>` | Lấy mã băm SHA-1 40 ký tự đầy đủ của một tham chiếu (HEAD, branch, tag) |
| `git cat-file -t <hash>` | Kiểm tra kiểu đối tượng (trả về: `commit`, `tree`, hoặc `blob`) |
| `git cat-file -p <hash>` | In nội dung giải nén của đối tượng (Pretty-print) |
| `git ls-tree <hash>` | Liệt kê danh sách các mục trong một tree object |

---

## 4. Truy Vết Từ Commit Tới File Dữ Liệu (Walkthrough)

Hãy cùng truy vết chuỗi con trỏ từ commit hiện tại xuống tận nội dung file `app.py`:

### Bước 4.1: Xem thông tin Commit Object
Lấy mã SHA và nội dung của commit hiện tại:

```bash
git cat-file -p HEAD
```{{exec}}

Đầu ra mẫu:
```text
tree 6f2a1b4...
parent 3c8e9d2...
author DevOps Engineer <devops@lab.local> 1790151836 +0700
committer DevOps Engineer <devops@lab.local> 1790151836 +0700

chore: add deploy scripts and secret token
```

Quan sát thấy dòng đầu tiên chứa con trỏ tới **Root Tree**.

### Bước 4.2: Xem cấu trúc Root Tree
Dùng `git ls-tree` để xem nội dung của tree mà commit trỏ tới:

```bash
git ls-tree HEAD
```{{exec}}

Đầu ra mẫu:
```text
100644 blob e69de29bb2d...    README.md
100644 blob a1b2c3d4e5f...    app.py
040000 tree f9e8d7c6b5a...    scripts
```

- Các file thông thường (`README.md`, `app.py`) trỏ trực tiếp tới đối tượng kiểu `blob`.
- Thư mục `scripts` trỏ tới một đối tượng kiểu `tree` con (`040000 tree`).

### Bước 4.3: Đọc nội dung Blob mà không cần mở file
Dùng `git cat-file -p` với mã SHA của blob `app.py`:

```bash
git cat-file -p HEAD:app.py
```{{exec}}

Kết quả in ra chính xác nội dung của file `app.py` được đọc trực tiếp từ Object Database!

---

## 5. Thử Thách & Xác Thực (Verification)

Sau khi đã nắm rõ cách Git liên kết các đối tượng, hãy tự tay thực hiện thử thách truy vết cây đối tượng sau:

### Kịch bản thử thách:
Trong repository `/root/devops-project`, bên trong thư mục `scripts/` có một file bí mật tên là `secret.txt`. Nhiệm vụ của bạn là sử dụng các lệnh plumbing để tìm mã SHA của blob `secret.txt`, đọc nội dung của nó và lưu vào file kết quả.

### Yêu cầu thử thách:
1. Đứng tại thư mục `/root/devops-project`.
2. Dùng lệnh `git ls-tree` duyệt từ commit `HEAD` vào thư mục con `scripts/` để xác định mã SHA của file `secret.txt`.
3. Dùng lệnh `git cat-file -p <sha_cua_secret_blob>` để trích xuất nội dung của file bí mật.
4. Ghi nội dung bóc tách được vào file: `/root/secret_recovered.txt`.
   *(Nội dung file phải đúng chuỗi token bí mật, không kèm ký tự thừa).*

*(Lưu ý: Bạn phải tự nhập lệnh, không có nút chạy tự động cho phần thử thách)*

<details>
<summary>Xem gợi ý các bước thực hiện</summary>

Duyệt vào thư mục scripts của commit hiện tại:
```bash
git ls-tree HEAD:scripts
```

Lệnh trên sẽ in ra mã SHA của file `secret.txt` (dạng: `100644 blob <SHA> secret.txt`).

Dùng mã SHA đó để đọc nội dung và ghi ra file:
```bash
git cat-file -p HEAD:scripts/secret.txt > /root/secret_recovered.txt
```
Hoặc dùng SHA trực tiếp:
```bash
git cat-file -p <MÃ_SHA_BLOB> > /root/secret_recovered.txt
cat /root/secret_recovered.txt
```

</details>

Sau khi hoàn thành và tạo file `/root/secret_recovered.txt`, hãy bấm nút **Check** bên dưới để hệ thống tự động xác thực!
