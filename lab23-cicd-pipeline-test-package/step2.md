# Bước 2: Cổng Chất Lượng & Cơ Chế Fail-Fast — Từ Pipeline Đỏ Sang Xanh

Giá trị lớn nhất của CI không nằm ở lúc pipeline xanh, mà ở lúc nó **đỏ**: pipeline chặn mã lỗi trước khi vào `main`. Trong bước này, bạn sẽ đóng vai người review nhánh `feature/discount` của đồng nghiệp, để pipeline phát hiện lỗi, sửa lỗi và bổ sung **cổng chất lượng coverage**.

---

## 1. Shift-Left & Fail-Fast

**Shift-Left** là nguyên tắc phát hiện lỗi càng sớm càng tốt trong vòng đời phần mềm. Chi phí sửa một bug tăng dần theo từng giai đoạn:

```text
Viết code  →  CI  →  Staging  →  Production
  rẻ nhất    rẻ      đắt         rất đắt (mất khách hàng, mất dữ liệu)
```

**Fail-Fast** là cách pipeline thực thi nguyên tắc đó:

- Sắp xếp các step **nhanh và rẻ trước** (gofmt mất vài mili giây), **chậm và đắt sau** (test, build image).
- Step nào thất bại (exit code khác 0) thì dừng ngay, không lãng phí tài nguyên chạy các step sau.

```text
gofmt ──[PASS]──► go vet ──[PASS]──► go test ──[FAIL]──► (dung, cac step sau bi bo qua)
```

---

## 2. Cổng Chất Lượng (Quality Gate) Với Coverage

Test pass chưa đủ: nếu chỉ 10% code được test thì 90% còn lại vẫn có thể chứa bug. **Quality Gate** là quy tắc "không đạt ngưỡng thì không qua", ví dụ coverage phải từ 70% trở lên.

Go có sẵn công cụ đọc file coverage:

```bash
go test -coverprofile=coverage.out ./...
go tool cover -func=coverage.out
```

Kết quả có dạng:

```text
cicd-app/main.go:20:    healthHandler   100.0%
cicd-app/main.go:25:    rootHandler     100.0%
...
total:                  (statements)    78.6%
```

Dòng `total:` chứa con số cần kiểm tra. Lấy giá trị bằng `awk`:

```bash
go tool cover -func=coverage.out | awk '/^total:/ {gsub("%","",$3); print $3}'
```

Vì Bash không so sánh được số thập phân, ta dùng `awk` để so sánh với ngưỡng:

```bash
awk -v c="78.6" 'BEGIN { exit (c >= 70) ? 0 : 1 }' && echo "Dat" || echo "Khong dat"
```

---

## 3. Thực Hành Từng Bước (Step-by-Step)

### Bước 2.1 — Đồng bộ workflow sang nhánh tính năng bằng Git Rebase

Nhánh `feature/discount` được tạo trước khi có file `ci.yml`. Chuyển sang nhánh tính năng và dùng kỹ thuật rebase để đưa các commit mới nhất từ `main` sang:

```bash
cd /root/cicd-app
git checkout feature/discount
git rebase main
ls -la .github/workflows/
```{{exec}}

Lúc này, nhánh `feature/discount` đã có file `.github/workflows/ci.yml`.

---

### Bước 2.2 — Kích hoạt pipeline và quan sát thất bại (Pipeline Đỏ)

Chạy pipeline cho nhánh hiện tại và lưu nhật ký lỗi vào `/root/ci-logs/step2-fail.log`:

```bash
act push -j test 2>&1 | tee /root/ci-logs/step2-fail.log
```{{exec}}

**Phân tích kết quả:**
- Step `Check formatting (gofmt)` thất bại (`Failure`), job dừng ngay lập tức.
- Các step phía sau (`go vet`, `Unit test`) hoàn toàn bị bỏ qua nhờ cơ chế **Fail-Fast**, giúp tiết kiệm tài nguyên tính toán.
- File vi phạm được hiển thị rõ trong log là `pricing.go`.

---

### Bước 2.3 — Chuẩn hóa format và phát hiện lỗi logic

Dùng công cụ `gofmt -w` để tự động chuẩn hóa lại thụt lề (thay 4 spaces bằng tabs) cho `pricing.go`:

```bash
gofmt -w pricing.go
git add pricing.go
git commit -m "style: chuan hoa format pricing.go"
```{{exec}}

Chạy lại pipeline để kiểm tra:

```bash
act push -j test
```{{exec}}

Lần này step format và static analysis đều vượt qua (`Success`), nhưng step `Unit test` lại báo lỗi (`Failure`) tại `TestApplyDiscount`:
```text
ApplyDiscount(100000, 20) = 20000, want 80000
```
Mã nguồn hàm giảm giá đang trả về *số tiền được giảm* (20.000) thay vì *giá sau khi giảm* (80.000).

---

### Bước 2.4 — Sửa lỗi logic trong hàm `ApplyDiscount`

Cập nhật lại tệp `pricing.go` với công thức tính đúng: `price - (price * percent / 100)`:

```bash
cat << 'EOF' > pricing.go
package main

import "errors"

// ErrInvalidPercent duoc tra ve khi phan tram giam gia nam ngoai khoang 0-100.
var ErrInvalidPercent = errors.New("percent must be between 0 and 100")

// ApplyDiscount tra ve gia sau khi giam (don vi VND).
func ApplyDiscount(price int, percent int) (int, error) {
    if percent < 0 || percent > 100 {
        return 0, ErrInvalidPercent
    }
    return price - (price * percent / 100), nil
}
EOF
```{{exec}}

Chuẩn hóa format bằng `gofmt` và kiểm tra cục bộ:

```bash
gofmt -w pricing.go
go test -v ./...
```{{exec}}

Commit bản sửa lỗi vào Git:

```bash
git add pricing.go
git commit -m "fix: sua cong thuc tinh gia giam"
```{{exec}}

---

### Bước 2.5 — Bổ sung cổng chất lượng Code Coverage 70% vào workflow

Cập nhật tệp `.github/workflows/ci.yml` để bổ sung step `Coverage gate (>= 70%)` ngay sau step unit test:

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

      - name: Coverage gate (>= 70%)
        run: |
          COVERAGE=$(go tool cover -func=coverage.out | awk '/^total:/ {gsub("%","",$3); print $3}')
          echo "Total coverage: ${COVERAGE}%"
          if ! awk -v c="$COVERAGE" 'BEGIN { exit (c >= 70) ? 0 : 1 }'; then
            echo "Coverage ${COVERAGE}% thap hon nguong 70%"
            exit 1
          fi
EOF
```{{exec}}

Commit thay đổi và chạy pipeline xác nhận trạng thái xanh hoàn toàn:

```bash
git add .github/workflows/ci.yml
git commit -m "ci: them cong chat luong coverage 70%"
act push -j test 2>&1 | tee /root/ci-logs/step2-pass.log
```{{exec}}

Quan sát log: tổng coverage đạt khoảng 82.4% (vượt ngưỡng 70%) và toàn bộ job đều thành công (`Job succeeded`).

---

### Bước 2.6 — Hợp nhất nhánh tính năng vào nhánh `main`

Sau khi code đã đáp ứng toàn bộ các tiêu chuẩn kiểm thử, chuyển về `main` và hợp nhất:

```bash
git checkout main
git merge --no-ff feature/discount -m "Merge branch 'feature/discount'"
git log --oneline --graph -8
```{{exec}}

Sau khi hoàn thành, hãy nhấn nút **Check** để hệ thống kiểm tra mã nguồn, cổng chất lượng và lịch sử pipeline.
