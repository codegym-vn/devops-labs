# Bước 3: Đóng Gói Docker Image, Gắn Tag Git SHA & Publish Lên Registry

Code đã qua cổng chất lượng. Phần **CD (Continuous Delivery)** của pipeline sẽ đóng gói code đó thành một **artifact bất biến** (Docker image), gắn nhãn truy vết được và đẩy lên registry, sẵn sàng triển khai ở bất kỳ môi trường nào.

---

## 1. Nguyên Tắc "Build Once, Deploy Many"

Image được build **một lần duy nhất** trong pipeline, sau đó cùng một image đó được triển khai lần lượt lên Dev → Staging → Production. Không build lại ở mỗi môi trường, vì mỗi lần build có thể cho ra kết quả khác (base image đã cập nhật, dependency đổi phiên bản...).

---

## 2. Chiến Lược Gắn Tag Image

| Kiểu tag | Ví dụ | Ưu điểm | Nhược điểm |
|---|---|---|---|
| `latest` | `cicd-app:latest` | Tiện khi thử nghiệm | **Thay đổi liên tục**, không biết đang chạy code nào, không rollback được |
| Git SHA | `cicd-app:sha-3f9a1c2` | **Truy vết chính xác** về commit, bất biến | Khó đọc với con người |
| SemVer | `cicd-app:1.2.0` | Dễ hiểu, phù hợp phát hành chính thức | Cần quy trình đánh số phiên bản |

Thực tế thường kết hợp: mỗi commit trên `main` tạo một tag **SHA** (bất biến) và cập nhật thêm tag `latest` (trỏ tới bản mới nhất). Production luôn triển khai theo tag SHA hoặc SemVer, **không bao giờ dùng `latest`**.

Trong GitHub Actions, commit đang chạy pipeline nằm ở biến môi trường `GITHUB_SHA` (40 ký tự). Lấy 7 ký tự đầu bằng cú pháp cắt chuỗi của Bash:

```bash
echo "sha-${GITHUB_SHA::7}"
```

Để chia sẻ biến giữa các step trong cùng job, ghi vào file đặc biệt `$GITHUB_ENV`:

```bash
echo "TAG=sha-${GITHUB_SHA::7}" >> "$GITHUB_ENV"   # step trước
echo "Tag hien tai: $TAG"                          # các step sau dùng được $TAG
```

---

## 3. Điều Phối Job: `needs` và `if`

Mặc định các job chạy **song song**. Hai từ khóa giúp điều phối thứ tự:

```yaml
jobs:
  test:
    ...
  package:
    needs: test                              # Chỉ chạy khi job test THÀNH CÔNG
    if: github.ref == 'refs/heads/main'      # Chỉ đóng gói trên nhánh main
```

- **`needs`** biến pipeline thành chuỗi phụ thuộc: test đỏ thì không bao giờ build image.
- **`if`** ngăn nhánh tính năng đẩy image lên registry. Nhánh `feature/**` chỉ được kiểm thử, không được phát hành.

---

## 4. Artifact Của Pipeline

Ngoài image, pipeline còn sinh ra các file có giá trị như báo cáo coverage hay file nhị phân. Action `actions/upload-artifact@v4` lưu chúng lại sau khi runner bị hủy, để tải về hoặc dùng ở job khác:

```yaml
- name: Upload coverage report
  uses: actions/upload-artifact@v4
  with:
    name: coverage-report
    path: coverage.out
```

Trong lab này, `act` lưu artifact vào thư mục `/tmp/artifacts` (đã cấu hình trong `~/.actrc`).

---

## 5. Thực Hành Từng Bước (Step-by-Step)

### Bước 3.1 — Đảm bảo đang làm việc trên nhánh `main`

Chuyển về nhánh `main` trước khi bổ sung quy trình đóng gói:

```bash
cd /root/cicd-app
git checkout main
```{{exec}}

---

### Bước 3.2 — Cập nhật workflow thêm lưu Artifact và Job `package`

Cập nhật tệp `.github/workflows/ci.yml` để hoàn thiện cả 2 job: `test` (có thêm step upload artifact) và `package` (chịu trách nhiệm build và publish Docker image):

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
EOF
```{{exec}}

**Giải thích các điểm cốt lõi trong job `package`:**
- `needs: test`: Thiết lập phụ thuộc chuỗi — chỉ khi job `test` thành công thì job `package` mới được kích hoạt.
- `if: github.ref == 'refs/heads/main'`: Điều kiện bảo vệ — chỉ phát hành image khi mã nguồn nằm trên nhánh chính thức `main`.
- `TAG=sha-${GITHUB_SHA::7}`: Trích xuất 7 ký tự hash SHA đầu tiên của commit hiện tại và đưa vào `$GITHUB_ENV` để các step sau có thể sử dụng `$TAG`.
- `docker build -t "$IMAGE:$TAG" -t "$IMAGE:latest" .`: Đóng gói ứng dụng thành một image bất biến gắn nhãn SHA, đồng thời trỏ nhãn `latest` về bản dựng mới nhất.
- `docker push`: Đẩy cả 2 tag lên registry nội bộ (`localhost:5000`).

---

### Bước 3.3 — Commit và chạy toàn bộ pipeline

Ghi nhận thay đổi vào Git và kiểm tra danh sách job qua `act`:

```bash
git add .github/workflows/ci.yml
git commit -m "ci: dong goi va publish docker image"
act -l
```{{exec}}

Kích hoạt toàn bộ pipeline cho sự kiện `push` và lưu nhật ký:

```bash
act push 2>&1 | tee /root/ci-logs/step3.log
```{{exec}}

Quan sát thứ tự thực thi: Job `Lint & Unit Test` chạy trước, sau khi hoàn tất thành công thì Job `Build & Publish Image` mới bắt đầu chạy và đẩy image lên registry.

---

### Bước 3.4 — Kiểm chứng kết quả trong Registry và Artifact

So sánh 7 ký tự SHA của commit HEAD với danh sách tag hiện có trong Registry:

```bash
git rev-parse --short=7 HEAD
curl -s http://localhost:5000/v2/cicd-app/tags/list
```{{exec}}

Registry sẽ hiển thị cả 2 tag: `latest` và `sha-<7 ký tự SHA>`.

Kiểm tra tệp artifact coverage đã được lưu lại trên máy:

```bash
find /tmp/artifacts -type f
```{{exec}}

> **Câu hỏi suy ngẫm:** Nếu chạy `act push` khi đang ở nhánh `feature/discount`, job `package` sẽ thế nào? Vì sao đây là hành vi mong muốn?

Sau khi hoàn thành, hãy nhấn nút **Check** để hệ thống kiểm tra job đóng gói, image trong registry và artifact.
