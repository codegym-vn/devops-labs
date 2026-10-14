# Bước 1: Khởi Tạo Kịch Bản Kiểm Thử Tải Baseline Với k6

Để đánh giá hiệu năng hệ thống một cách khoa học, bước đầu tiên của kỹ sư SRE là xây dựng một **Kịch bản kiểm thử đường cơ sở (Baseline Load Test)**. Đường cơ sở này phản ánh hành vi và thời gian phản hồi của hệ thống ở điều kiện vận hành bình thường (Normal Operating Conditions), làm chuẩn mực để so sánh khi nâng cấp mã nguồn hoặc khi hệ thống chịu tải nặng.

---

### 1. Cấu Trúc Cơ Bản Của Một Kịch Bản k6

Một tệp kịch bản kiểm thử tải k6 gồm 3 thành phần chính:
1. **Phần khởi tạo (Init context):** Import các thư viện k6 (`k6/http`, `check`, `sleep`).
2. **Cấu hình tùy chọn (Options):** Khai báo các tham số thực thi như số người dùng ảo (`vus` - Virtual Users) và thời gian chạy (`duration`).
3. **Hàm thực thi chính (Default function):** Logic gửi request mà mỗi Virtual User (VU) sẽ lặp đi lặp lại liên tục trong suốt thời gian kiểm thử.

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

// 1. Khai bao tuy chon tai
export const options = {
  vus: 10,         // 10 nguoi dung ao truy cap dong thoi
  duration: '15s', // Thoi gian thuc thi 15 giay
};

// 2. Logic thuc thi cua moi VU
export default function () {
  const res = http.get('http://localhost:8080/api/products');
  check(res, {
    'status is 200': (r) => r.status === 200,
  });
  sleep(0.1); // Khoang nghi (think time) 100ms giua cac request
}
```

---

### 2. Tạo Kịch Bản Kiểm Thử Baseline: `load-baseline.js`

Hãy tạo tệp kịch bản kiểm thử tải tại thư mục `/root/load-test-lab/scripts/load-baseline.js`:

```bash
cat << 'EOF' > /root/load-test-lab/scripts/load-baseline.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 10,
  duration: '15s',
};

export default function () {
  const res = http.get('http://localhost:8080/api/products');

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response has products': (r) => r.body.includes('Cloud Server Node'),
  });

  sleep(0.1);
}
EOF
```

---

### 3. Chạy Thử Kịch Bản Ở Mức Smoke Test (1 VU)

Trước khi chạy tải diện rộng, hãy luôn chạy thử ở chế độ **Smoke Test** (1 VU trong 3 giây) để đảm bảo cú pháp JavaScript chính xác và máy chủ mục tiêu đang phản hồi bình thường:

```bash
k6 run --vus 1 --duration 3s /root/load-test-lab/scripts/load-baseline.js
```

Sau khi chạy xong, bạn sẽ thấy kết quả in ra màn hình tóm tắt với tỷ lệ check đạt `100.00%`:
```text
[PASS] status is 200
[PASS] response has products
```

Sau khi hoàn thành bước này, nhấn **Check** để hệ thống kiểm tra tính hợp lệ của kịch bản Baseline!
