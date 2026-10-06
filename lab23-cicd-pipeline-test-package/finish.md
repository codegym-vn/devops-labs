# Hoàn Thành: Xây Dựng Pipeline CI/CD Cơ Bản — Kiểm Thử & Đóng Gói Ứng Dụng

Chúc mừng bạn đã hoàn thành **Lab 23**! Bạn đã biến toàn bộ quy trình kiểm thử và đóng gói thủ công thành một **pipeline tự động, nhất quán và truy vết được**, nền móng của mọi hệ thống phát hành phần mềm hiện đại.

---

## Năng Lực Đã Đạt Được

- **Pipeline as Code:** viết workflow GitHub Actions với trigger, job, step, chạy cục bộ bằng `act`.
- **Quality Gates:** kiểm tra format (`gofmt`), phân tích tĩnh (`go vet`), unit test và ngưỡng coverage 70%.
- **Fail-Fast & Shift-Left:** đọc log pipeline đỏ, khoanh vùng lỗi và sửa đúng chỗ thay vì sửa test.
- **Continuous Delivery:** đóng gói image bất biến, gắn tag Git SHA, publish lên registry, lưu artifact.
- **Release & Rollback:** smoke test image sau build, phát hành phiên bản mới và chạy lại bản cũ bằng tag SHA.

---

## Lời Giải Tham Khảo: `ci.yml` Hoàn Chỉnh

```yaml
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

      - name: Upload coverage report
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: coverage.out

  package:
    name: Build & Publish Image
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    env:
      IMAGE: localhost:5000/cicd-app
    steps:
      - name: Checkout source
        uses: actions/checkout@v4

      - name: Compute image tag
        run: echo "TAG=sha-${GITHUB_SHA::7}" >> "$GITHUB_ENV"

      - name: Build image
        run: docker build -t "$IMAGE:$TAG" -t "$IMAGE:latest" .

      - name: Push image
        run: |
          docker push "$IMAGE:$TAG"
          docker push "$IMAGE:latest"

      - name: Smoke test
        run: |
          docker rm -f cicd-app-smoke 2>/dev/null || true
          docker run -d --name cicd-app-smoke -p 8088:8080 "$IMAGE:$TAG"
          for i in $(seq 1 10); do
            if curl -fsS http://localhost:8088/healthz; then
              echo ""
              echo "Smoke test passed (lan thu $i)"
              exit 0
            fi
            sleep 1
          done
          echo "Smoke test that bai"
          docker logs cicd-app-smoke
          exit 1
```

---

## Bảng Tra Cứu Nhanh

### Cú pháp GitHub Actions

| Từ khóa | Ý nghĩa | Ví dụ |
| :--- | :--- | :--- |
| `on` | Sự kiện kích hoạt | `push`, `pull_request`, `schedule`, `workflow_dispatch` |
| `jobs.<id>.runs-on` | Loại runner | `ubuntu-latest` |
| `jobs.<id>.needs` | Job phụ thuộc | `needs: test` hoặc `needs: [test, lint]` |
| `jobs.<id>.if` | Điều kiện chạy job/step | `github.ref == 'refs/heads/main'` |
| `env` | Biến môi trường (workflow/job/step) | `IMAGE: localhost:5000/cicd-app` |
| `uses` | Gọi action tái sử dụng | `actions/checkout@v4` |
| `run` | Chạy lệnh shell (`run: \|` cho nhiều dòng) | `go test ./...` |
| `$GITHUB_ENV` | Chia sẻ biến giữa các step | `echo "TAG=x" >> "$GITHUB_ENV"` |
| `$GITHUB_SHA` | Commit đang chạy pipeline | `${GITHUB_SHA::7}` |

### Lệnh `act`

| Lệnh | Tác dụng |
| :--- | :--- |
| `act -l` | Liệt kê job trong workflow |
| `act push` | Giả lập sự kiện push, chạy toàn bộ workflow |
| `act push -j test` | Chỉ chạy job `test` |
| `act pull_request` | Giả lập sự kiện pull request |
| `act -n` | Dry-run, chỉ hiển thị kế hoạch |
| `act -P ubuntu-latest=<image>` | Chỉ định image runner |
| `act --artifact-server-path <dir>` | Bật lưu artifact cục bộ |

### Chiến lược tag image

| Tag | Dùng khi | Production? |
| :--- | :--- | :---: |
| `latest` | Thử nghiệm nhanh | Khong |
| `sha-<7 ký tự>` | Mọi commit trên `main`, truy vết và rollback | Co |
| `1.2.0` (SemVer) | Phát hành chính thức qua Git tag | Co |

---

## Checklist Tự Đánh Giá

- [x] Giải thích được workflow, trigger, job, step, runner, artifact
- [x] Viết workflow kiểm tra format, phân tích tĩnh và unit test
- [x] Đọc log pipeline thất bại và xác định chính xác step, file, test lỗi
- [x] Thiết lập cổng chất lượng coverage với ngưỡng cụ thể
- [x] Điều phối job bằng `needs` và giới hạn phát hành bằng `if`
- [x] Gắn tag image theo Git SHA và publish lên registry
- [x] Lưu báo cáo bằng `actions/upload-artifact`
- [x] Viết smoke test có cơ chế thử lại và diễn tập rollback

---

## Đưa Pipeline Lên GitHub Thật

File `ci.yml` trong bài chạy được trên GitHub với 2 thay đổi nhỏ:

1. Đổi `IMAGE` sang registry thật, ví dụ `ghcr.io/<github-user>/cicd-app`.
2. Thêm step đăng nhập registry trước khi push:

```yaml
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
```

Và cấp quyền cho job `package`: `permissions: { contents: read, packages: write }`.
