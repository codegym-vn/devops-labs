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
gofmt ──✅──► go vet ──✅──► go test ──❌──► (dừng, các step sau bị bỏ qua)
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

## 3. Thử Thách Thực Hành (DIY Challenge)

### Nhiệm vụ 1: Đưa workflow vào nhánh tính năng

Nhánh `feature/discount` được tạo **trước khi** có `ci.yml`, nên chưa có pipeline. Hãy chuyển sang nhánh đó và **rebase lên `main`** (kỹ thuật ở Lab 7):

```bash
cd /root/cicd-app
git checkout feature/discount
git rebase main
ls .github/workflows/
```

### Nhiệm vụ 2: Chạy pipeline và quan sát thất bại

```bash
act push -j test 2>&1 | tee /root/ci-logs/step2-fail.log
```

Pipeline sẽ **đỏ**. Hãy đọc log và trả lời:
- Step nào thất bại? Các step phía sau có được chạy không?
- File nào bị báo lỗi?

### Nhiệm vụ 3: Sửa lần lượt từng lỗi

1. **Lỗi format:** xem chênh lệch bằng `gofmt -d pricing.go`, sửa bằng `gofmt -w pricing.go`, rồi commit với thông điệp `style: chuan hoa format pricing.go`.
2. Chạy lại `act push -j test`. Pipeline tiếp tục đỏ ở một step khác. Đọc thông báo `FAIL` trong log để biết test nào sai, giá trị mong đợi là bao nhiêu.
3. **Lỗi logic:** mở `pricing.go`, sửa công thức trong hàm `ApplyDiscount` sao cho trả về **giá sau khi giảm** (ví dụ 100000 giảm 20% còn 80000). Kiểm tra cục bộ bằng `go test ./...`, rồi commit với thông điệp `fix: sua cong thuc tinh gia giam`.

> **Không** được sửa file test để "ép" pipeline xanh. Test mô tả đúng nghiệp vụ, code mới là phần sai.

### Nhiệm vụ 4: Bổ sung cổng chất lượng coverage

Thêm vào job `test` một step **ngay sau step Unit test**:

- **Tên step:** `Coverage gate (>= 70%)`
- Dùng `go tool cover -func=coverage.out` để lấy tổng coverage
- In ra giá trị coverage hiện tại
- Nếu coverage **nhỏ hơn 70** thì in cảnh báo và `exit 1`

> **Gợi ý cho step kiểm tra coverage:**
> ```yaml
>       - name: Coverage gate (>= 70%)
>         run: |
>           COVERAGE=$(go tool cover -func=coverage.out | awk '/^total:/ {gsub("%","",$3); print $3}')
>           echo "Total coverage: ${COVERAGE}%"
>           if ! awk -v c="$COVERAGE" 'BEGIN { exit (c >= 70) ? 0 : 1 }'; then
>             echo "Coverage ${COVERAGE}% thap hon nguong 70%"
>             exit 1
>           fi
> ```

Commit thay đổi với thông điệp `ci: them cong chat luong coverage 70%`, rồi chạy pipeline và lưu log:

```bash
act push -j test 2>&1 | tee /root/ci-logs/step2-pass.log
```

Lần này pipeline phải **xanh** và log in ra giá trị coverage (khoảng 82%).

### Nhiệm vụ 5: Merge vào main

Khi pipeline đã xanh, hợp nhất nhánh tính năng vào `main`:

```bash
git checkout main
git merge --no-ff feature/discount -m "Merge branch 'feature/discount'"
git log --oneline --graph -8
```

Sau khi hoàn thành, hãy bấm nút **Check** để hệ thống kiểm tra mã nguồn trên `main`, cổng chất lượng và lịch sử chạy pipeline.
