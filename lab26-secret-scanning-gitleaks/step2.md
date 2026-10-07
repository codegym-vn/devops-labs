# Bước 2: Quét Lịch Sử Git Commit & Xuất Báo Cáo Truy Vết

Một sai lầm rất phổ biến của nhiều kỹ sư là: Khi phát hiện lộ mật khẩu, họ tạo ngay một commit mới để xóa tệp đó và tin rằng hệ thống đã an toàn. Trong bước này, bạn sẽ chứng minh rằng **xóa file trong commit mới không thể che giấu được secret trong lịch sử Git**.

---

## 1. Giả Lập Tình Huống Xóa File Nhưng Không Xóa Lịch Sử

Thực hiện xóa tệp `config.json` và commit thay đổi lên kho lưu trữ:

```bash
cd /root/secret-leak-lab
rm -f config.json
git add config.json
git commit -m "fix: xoa bo file config chua khoa AWS"
```{{exec}}

Kiểm tra thư mục hiện tại:

```bash
ls -la config.json 2>/dev/null || echo "[INFO] File config.json da bien mat khoi Working Tree!"
```{{exec}}

Nếu chỉ quét cây thư mục hiện tại với `--no-git`, bạn sẽ không còn thấy khóa AWS nữa:

```bash
gitleaks detect --no-git --source .
```{{exec}}

Tuy nhiên, mã độc và các bot quét trên Internet không quét thư mục hiện tại — chúng duyệt toàn bộ lịch sử commit của kho lưu trữ.

---

## 2. Quét Toàn Bộ Lịch Sử Git Bằng Gitleaks

Chạy Gitleaks ở chế độ quét lịch sử Git (mặc định):

```bash
gitleaks detect --source . -v
```{{exec}}

Quan sát kết quả:
* Gitleaks truy vết ngược về từng commit trong quá khứ.
* Chỉ ra chính xác mã hash của commit khởi tạo: `commit: ...`
* Tên tác giả (Author), email, và dòng code chính xác nơi khóa `AKIAIOSFODNN7EXAMPLE` đã từng xuất hiện.
* Tiếp tục phát hiện chuỗi kết nối chứa mật khẩu trong tệp `database.js`.

---

## 3. Xuất Báo Cáo Truy Vết Lịch Sử Định Dạng JSON

Xuất toàn bộ kết quả phát hiện từ lịch sử Git ra tệp JSON:

```bash
gitleaks detect --source . --report-path gitleaks-history.json
```{{exec}}

Xem chi tiết danh sách các commit bị nhiễm secret:

```bash
cat gitleaks-history.json | grep -E "Commit|RuleID|File" | head -n 12
```{{exec}}

Điều này khẳng định nguyên tắc bảo mật tối thượng: Khi secret đã vô tình bị commit lên Git, biện pháp an toàn duy nhất là **Revoke / Rotate (Thu hồi và đổi khóa mới ngay lập tức)**, không thể dựa vào việc xóa file trên Git.

Nhấn **Check** để hoàn thành Bước 2!
