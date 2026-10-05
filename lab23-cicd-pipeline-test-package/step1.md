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

## 3. Thử Thách Thực Hành (DIY Challenge)

### Nhiệm vụ 1: Viết workflow CI

Tạo tệp `/root/cicd-app/.github/workflows/ci.yml` với yêu cầu:

- **Tên workflow:** `CI`
- **Trigger (`on`):**
  - `push` trên các nhánh `main` và `feature/**`
  - `pull_request` vào nhánh `main`
- **Một job có id là `test`**, tên hiển thị `Lint & Unit Test`, chạy trên `ubuntu-latest`, gồm các step theo thứ tự:
  1. Checkout mã nguồn bằng `actions/checkout@v4`
  2. Cài Go bằng `actions/setup-go@v5` với `go-version: "1.22"` và `cache: false`
  3. **Kiểm tra format:** chạy `gofmt -l .`, nếu kết quả **không rỗng** thì in danh sách file và `exit 1`
  4. **Phân tích tĩnh:** `go vet ./...`
  5. **Unit test:** `go test -v -coverprofile=coverage.out ./...`

> **Gợi ý cho step kiểm tra format:** lệnh `gofmt -l` luôn trả về exit code 0 kể cả khi có file sai format, nên bạn phải tự kiểm tra output:
> ```bash
> UNFORMATTED=$(gofmt -l .)
> if [ -n "$UNFORMATTED" ]; then
>   echo "Cac file chua dung chuan gofmt:"
>   echo "$UNFORMATTED"
>   exit 1
> fi
> ```
> Trong YAML, dùng `run: |` để viết lệnh nhiều dòng.

### Nhiệm vụ 2: Commit và chạy pipeline

Commit workflow vào nhánh `main`:

```bash
git add .github/workflows/ci.yml
git commit -m "ci: them workflow kiem thu tu dong"
```

Kiểm tra `act` đã nhận diện được job:

```bash
act -l
```

Chạy pipeline và **lưu log** để hệ thống chấm điểm:

```bash
act push -j test 2>&1 | tee /root/ci-logs/step1.log
```

> Lần chạy đầu tiên, `actions/setup-go` cần tải Go về runner nên mất khoảng 30-60 giây.

Quan sát log: mỗi step được đánh dấu `✅ Success`, cuối cùng là dòng `🏁 Job succeeded`.

Sau khi hoàn thành, hãy bấm nút **Check** để hệ thống kiểm tra workflow và kết quả chạy pipeline.
