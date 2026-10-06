# Bước 1: Pipeline CI Đầu Tiên — Lint & Unit Test Với GitHub Actions

Trong bước này, bạn sẽ khám phá ứng dụng mẫu, chạy kiểm thử thủ công để hiểu "pipeline cần làm gì", sau đó chuyển toàn bộ các thao tác đó thành một **workflow GitHub Actions** và chạy nó bằng `act`.

---

## 1. Khám Phá Ứng Dụng Mẫu

Di chuyển vào repo và quan sát cấu trúc:

```bash
cd /root/cicd-app
ls -la
git log --oneline --all --graph
```{{exec}}

Repo gồm:

| File | Vai trò |
|---|---|
| `main.go` | Go microservice với 2 endpoint `/` và `/healthz` |
| `main_test.go` | Unit test cho các handler |
| `Dockerfile` | Multi-stage build, chạy non-root UID 10001 (kế thừa Lab 11) |
| `go.mod` | Khai báo module, chỉ dùng thư viện chuẩn |

Ngoài nhánh `main`, repo còn nhánh `feature/discount` do một đồng nghiệp đẩy lên. Chúng ta sẽ xử lý nhánh này ở Bước 2.

Chạy thử 3 bước kiểm tra chất lượng mà mọi dự án Go đều cần:

```bash
gofmt -l .            # Liệt kê file sai chuẩn format (rỗng = đạt)
go vet ./...          # Phân tích tĩnh, phát hiện lỗi tiềm ẩn
go test -v -cover ./...
```{{exec}}

Đây chính là những việc **pipeline CI sẽ làm thay bạn** trên mọi commit.

---

## 2. Giải Phẫu Một Workflow GitHub Actions

Workflow là file YAML đặt trong thư mục `.github/workflows/`. Cấu trúc phân cấp:

```text
Workflow (ci.yml)
├── on:            → Trigger: sự kiện nào kích hoạt pipeline (push, pull_request...)
└── jobs:          → Tập hợp các job, mặc định chạy song song
    └── <job-id>:
        ├── runs-on:   → Loại runner (máy chạy job), vd: ubuntu-latest
        └── steps:     → Các bước chạy TUẦN TỰ trong cùng một runner
            ├── uses:  → Gọi một action có sẵn (tái sử dụng)
            └── run:   → Chạy lệnh shell
```

Ví dụ minh họa một workflow tối giản:

```yaml
name: Demo
on:
  push:
    branches: [main]
jobs:
  hello:
    runs-on: ubuntu-latest
    steps:
      - name: Lay ma nguon
        uses: actions/checkout@v4
      - name: Chao the gioi
        run: echo "Hello CI"
```

**Các khái niệm quan trọng:**

- **Runner** là máy "sạch" được tạo mới cho mỗi job, chạy xong sẽ bị hủy. Vì vậy pipeline luôn chạy trong môi trường nhất quán, không bị ảnh hưởng bởi máy của lập trình viên.
- **`actions/checkout`** tải mã nguồn vào runner. Thiếu bước này, runner không có code để kiểm tra.
- **`actions/setup-go`** cài đúng phiên bản Go vào runner.
- **Fail-Fast:** nếu một step trả về exit code khác 0, các step sau bị bỏ qua và job được đánh dấu **failed**.

### Cách `act` mô phỏng GitHub

| Trên GitHub | Với `act` trong lab này |
|---|---|
| `git push` tự kích hoạt workflow | Bạn gõ `act push` để giả lập sự kiện push |
| Runner là VM `ubuntu-latest` của GitHub | Runner là container `catthehacker/ubuntu:act-22.04` (cấu hình sẵn trong `~/.actrc`) |
| Xem log trên tab Actions | Log in thẳng ra terminal |

Một số lệnh `act` hữu ích:

```bash
act -l                 # Liệt kê các job trong workflow
act push               # Chạy toàn bộ workflow với sự kiện push
act push -j test       # Chỉ chạy job có id là "test"
```

> **Lưu ý:** `act` chạy trên **thư mục làm việc hiện tại**, kể cả thay đổi chưa commit. Tuy nhiên biến `GITHUB_SHA` luôn là commit `HEAD`. Hãy tập thói quen **commit trước, chạy pipeline sau**.

---

## 3. Thực Hành Từng Bước (Step-by-Step)

### Bước 1.1 — Tạo file định nghĩa workflow CI

Đảm bảo bạn đang ở thư mục dự án và tạo thư mục chứa workflow `.github/workflows/`:

```bash
cd /root/cicd-app
mkdir -p .github/workflows
```{{exec}}

Tạo tệp `.github/workflows/ci.yml` với cấu hình job `test` hoàn chỉnh:

```bash
cat << 'EOF' > .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, "feature/**"]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Lint & Unit Test
    runs-on: ubuntu-latest
    steps:
      - name: Checkout source
        uses: actions/checkout@v4

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: "1.22"
          cache: false

      - name: Check formatting (gofmt)
        run: |
          UNFORMATTED=$(gofmt -l .)
          if [ -n "$UNFORMATTED" ]; then
            echo "Cac file chua dung chuan gofmt:"
            echo "$UNFORMATTED"
            exit 1
          fi

      - name: Static analysis (go vet)
        run: go vet ./...

      - name: Unit test
        run: go test -v -coverprofile=coverage.out ./...
EOF
```{{exec}}

**Giải thích các thành phần trong workflow:**
- `on.push.branches`: Kích hoạt pipeline khi có commit đẩy lên `main` hoặc các nhánh tính năng `feature/**`.
- `actions/checkout@v4`: Tải toàn bộ mã nguồn vào máy runner.
- `actions/setup-go@v5`: Thiết lập môi trường Go 1.22 trên runner.
- `gofmt -l .`: Kiểm tra định dạng code. Lệnh in ra danh sách file chưa đúng chuẩn; nếu có file vi phạm thì `exit 1` để dừng pipeline.
- `go vet ./...`: Phân tích cú pháp tĩnh để phát hiện các lỗi tiềm ẩn.
- `go test ... -coverprofile=coverage.out`: Chạy toàn bộ unit test và xuất số liệu độ phủ code ra file `coverage.out`.

---

### Bước 1.2 — Commit workflow vào nhánh `main`

Ghi nhận file workflow mới vào lịch sử Git:

```bash
git add .github/workflows/ci.yml
git commit -m "ci: them workflow kiem thu tu dong"
```{{exec}}

Kiểm tra `act` đã nhận diện được workflow và job:

```bash
act -l
```{{exec}}

Kết quả sẽ hiển thị bảng gồm job `test` với sự kiện kích hoạt `push` và `pull_request`.

---

### Bước 1.3 — Kích hoạt pipeline bằng `act` và quan sát kết quả

Chạy job `test` thông qua `act` và lưu nhật ký log vào thư mục `/root/ci-logs/`:

```bash
act push -j test 2>&1 | tee /root/ci-logs/step1.log
```{{exec}}

> **Lưu ý:** Ở lần chạy đầu tiên, `actions/setup-go` sẽ tải bộ cài Go vào runner nên có thể mất từ 30-60 giây.

**Quan sát đầu ra:**
- Mỗi step khi chạy thành công sẽ hiển thị trạng thái `Success`.
- Dòng kết thúc hiển thị thông báo `Job succeeded`.

Sau khi hoàn thành, hãy nhấn nút **Check** để hệ thống kiểm tra workflow và kết quả thực thi của bạn.
