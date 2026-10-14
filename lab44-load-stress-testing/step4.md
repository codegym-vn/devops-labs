# Bước 4: Thiết Lập Ngưỡng Kiểm Định Tự Động (Thresholds / Quality Gate)

Trong quy trình CI/CD hiện đại (GitLab CI, GitHub Actions, Jenkins), kiểm thử tải không chỉ chạy thủ công khi có sự cố. Chúng ta biến kịch bản k6 thành một **Cổng kiểm soát chất lượng tự động (Quality Gate)**:
- Nếu một lập trình viên vô tình đưa vào đoạn mã làm chậm API (Performance Regression) hoặc gây rò rỉ bộ nhớ, k6 sẽ tự động đánh trượt (Exit code khác 0), chặn đứng bản build không cho triển khai lên Staging hoặc Production.

---

### 1. Cơ Chế Thresholds Trong k6

k6 cho phép bạn khai báo các tiêu chí chấp nhận (Pass/Fail criteria) cho bất kỳ chỉ số đo lường nào:

```javascript
export const options = {
  vus: 15,
  duration: '20s',
  thresholds: {
    // 1. Ty le loi HTTP (4xx, 5xx) phai nho hon 1%
    http_req_failed: ['rate<0.01'],

    // 2. 95% so request phai phan hoi duoi 250ms va 99% phai duoi 450ms
    http_req_duration: ['p(95)<250', 'p(99)<450'],

    // 3. Ty le check thanh cong phai dat tren 99%
    checks: ['rate>0.99'],
  },
};
```

Khi bất kỳ ngưỡng nào bị vi phạm, k6 sẽ đánh dấu đỏ và thoát với mã lỗi `99`, làm sập bước pipeline CI/CD ngay lập tức.

---

### 2. Tạo Kịch Bản Quality Gate: `quality-gate.js`

Hãy tạo tệp kịch bản kiểm tra chất lượng tự động tại `/root/load-test-lab/scripts/quality-gate.js`:

```bash
cat << 'EOF' > /root/load-test-lab/scripts/quality-gate.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 15,
  duration: '15s',
  thresholds: {
    http_req_failed: ['rate<0.01'],                 // Loi duoi 1%
    http_req_duration: ['p(95)<300', 'p(99)<500'],  // p95 < 300ms, p99 < 500ms
    checks: ['rate>0.99'],                          // Checks phai pass tren 99%
  },
};

export default function () {
  // Goi song song ca GET san pham va POST don hang o muc tai on dinh
  const resProducts = http.get('http://localhost:8080/api/products');
  check(resProducts, {
    'products status is 200': (r) => r.status === 200,
  });

  const payload = JSON.stringify({ item: 'Cloud Server Node', quantity: 1 });
  const params = { headers: { 'Content-Type': 'application/json' } };
  const resOrder = http.post('http://localhost:8080/api/orders', payload, params);

  check(resOrder, {
    'order status is 201': (r) => r.status === 201,
  });

  sleep(0.1);
}
EOF
```

---

### 3. Thực Thi Kịch Bản Quality Gate

Chạy kịch bản và quan sát cách k6 kiểm định các tiêu chí:

```bash
k6 run --summary-export=/root/load-test-lab/reports/quality-gate-summary.json /root/load-test-lab/scripts/quality-gate.js
```

Sau khi chạy xong, hãy kiểm tra mã thoát (Exit code) của lệnh:

```bash
echo "Exit code của k6: $?"
```

Nếu hệ thống đạt chuẩn, mã thoát sẽ là `0` và trên màn hình hiển thị:
```text
[PASS] http_req_duration..............: p(95)<300 p(99)<500
[PASS] http_req_failed................: rate<0.01
[PASS] checks.........................: rate>0.99
```

---

### 4. Xuất Báo Cáo Tổng Hợp Nghiệm Thu Hiệu Năng

Tạo tệp báo cáo tổng kết nghiệm thu tại `/root/load-test-lab/reports/performance-test-report.json`:

```bash
cat << 'EOF' > /root/load-test-lab/reports/performance-test-report.json
{
  "test_suite": "E-COMMERCE-API-PERFORMANCE-SUITE",
  "engine": "k6-oss",
  "quality_gate": {
    "status": "PASSED",
    "thresholds": {
      "http_req_failed": "<1%",
      "http_req_duration_p95": "<300ms",
      "http_req_duration_p99": "<500ms"
    }
  },
  "verified_at": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
}
EOF
cat /root/load-test-lab/reports/performance-test-report.json | jq .
```

Sau khi hoàn tất, nhấn **Check** để hệ thống kiểm tra và hoàn thành toàn bộ bài Lab 44!
