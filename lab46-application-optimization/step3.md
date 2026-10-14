# Bước 3: Triển Khai Tối Ưu Tầng Ứng Dụng Với Cache-Aside

Sau khi đã có số liệu Benchmark Before, bạn sẽ tiến hành can thiệp kỹ thuật: kích hoạt tầng bộ nhớ đệm **Cache-Aside** cho dịch vụ Catalog để loại bỏ hiện tượng truy vấn dữ liệu lặp lại.

---

### 1. Kích Hoạt Tầng Cache Trong Tệp Cấu Hình

Cập nhật giá trị `CACHE_ENABLED=true` trong tệp cấu hình `/root/app-opt-lab/config/app.env`:

```bash
sed -i 's/CACHE_ENABLED=false/CACHE_ENABLED=true/' /root/app-opt-lab/config/app.env
```

Kiểm tra lại nội dung tệp cấu hình sau khi sửa:

```bash
cat /root/app-opt-lab/config/app.env
```

*Đảm bảo dòng cấu hình hiển thị:*
```text
CACHE_ENABLED=true
```

---

### 2. Xác Nhận Trạng Thái Trên Endpoint Health

Kiểm tra xem ứng dụng đã nhận diện cấu hình Cache mới hay chưa:

```bash
curl -s http://localhost:8080/health | jq .
```

*Kết quả mong đợi:*
```json
{
  "status": "UP",
  "cache": "ENABLED"
}
```

---

### 3. Kiểm Chứng Chu Trình Cache MISS và Cache HIT

Gửi lần lượt 2 request liên tiếp để kiểm tra hành vi thực tế của mô hình Cache-Aside:

**Lần 1 (Cache MISS - Lần đầu tiên gọi API):**
```bash
curl -i -s http://localhost:8080/api/catalog | head -n 10
```
*Quan sát:* Header trả về `X-Cache-Status: MISS`. Dữ liệu được tính toán và lưu vào bộ nhớ đệm với thời hạn 60 giây.

**Lần 2 (Cache HIT - Các lần gọi tiếp theo):**
```bash
curl -i -s http://localhost:8080/api/catalog | head -n 10
```
*Quan sát:* Header chuyển sang `X-Cache-Status: HIT`. Dữ liệu được trả về tức thời từ bộ nhớ đệm mà không cần tính toán lại.

Sau khi đã kích hoạt Cache thành công và xác thực được trạng thái `X-Cache-Status: HIT`, nhấn **Check** để hoàn thành Bước 3!
