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

## 5. Thử Thách Thực Hành (DIY Challenge)

Đảm bảo bạn đang ở nhánh `main`:

```bash
cd /root/cicd-app
git checkout main
```

### Nhiệm vụ 1: Lưu báo cáo coverage

Thêm vào **cuối job `test`** step `Upload coverage report` dùng `actions/upload-artifact@v4`, tên artifact `coverage-report`, đường dẫn `coverage.out`.

### Nhiệm vụ 2: Thêm job `package`

Thêm job mới có id **`package`**, tên hiển thị `Build & Publish Image`, yêu cầu:

- Chạy trên `ubuntu-latest`
- **Phụ thuộc** job `test`
- **Chỉ chạy** khi `github.ref` là `refs/heads/main`
- Khai báo biến môi trường cấp job: `IMAGE: localhost:5000/cicd-app`
- Các step:
  1. Checkout mã nguồn
  2. **Tính tag:** ghi `TAG=sha-<7 ký tự đầu của GITHUB_SHA>` vào `$GITHUB_ENV`
  3. **Build image:** `docker build` gắn **đồng thời 2 tag** `$IMAGE:$TAG` và `$IMAGE:latest`
  4. **Push image:** `docker push` cả 2 tag lên registry

> Runner của `act` dùng chung Docker daemon và mạng `host` với máy, nên lệnh `docker` trong job đẩy được image lên `localhost:5000`.

### Nhiệm vụ 3: Commit rồi chạy toàn bộ pipeline

```bash
git add .github/workflows/ci.yml
git commit -m "ci: dong goi va publish docker image"
act -l
act push 2>&1 | tee /root/ci-logs/step3.log
```

Quan sát thứ tự: job `package` chỉ bắt đầu **sau khi** job `test` thành công.

### Nhiệm vụ 4: Kiểm chứng kết quả

Đối chiếu tag trong registry với commit hiện tại:

```bash
git rev-parse --short=7 HEAD
curl -s http://localhost:5000/v2/cicd-app/tags/list
```

Kiểm tra artifact coverage:

```bash
find /tmp/artifacts -type f
```

**Câu hỏi suy ngẫm:** Nếu chạy `act push` khi đang ở nhánh `feature/discount`, job `package` sẽ thế nào? Vì sao đây là hành vi mong muốn?

Sau khi hoàn thành, hãy bấm nút **Check** để hệ thống kiểm tra job đóng gói, image trong registry và artifact.
