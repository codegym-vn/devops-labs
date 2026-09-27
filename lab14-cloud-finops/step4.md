# Bước 4: Phát hiện tài nguyên idle và lập báo cáo

## Lý thuyết: Right-sizing

Điều chỉnh instance type cho phù hợp workload thực tế:

```
t3.xlarge ($0.166/giờ, CPU avg 3%) → t3.micro ($0.010/giờ)
Tiết kiệm: $111/tháng
```

| Chiến lược | Tiết kiệm | Ghi chú |
|-----------|-----------|---------|
| Right-sizing | 20–50% | Cần test trước |
| Schedule stop (ngoài giờ) | 60–70% | Chỉ non-prod |
| Reserved Instance (1 năm) | ~30% | Cam kết dài hạn |
| Spot Instance | 60–90% | Có thể bị interrupt |

---

## Thực hành

### 4.1 — Phát hiện instances idle (CPU < 30%)

```bash
python3 /opt/lab-data/find-idle-resources.py \
  --metrics /opt/lab-data/resource-utilization.json \
  --cpu-threshold 30
```

### 4.2 — Tính chi phí tiết kiệm

```bash
python3 << 'EOF'
import json

PRICING = {
    "t3.micro": 0.0104, "t3.small": 0.0208,
    "t3.medium": 0.0416, "t3.large": 0.0832, "t3.xlarge": 0.1664
}

with open("/opt/lab-data/resource-utilization.json") as f:
    instances = json.load(f)

recommendations = {
    "api-server-prod":   (None,       "Giữ nguyên"),
    "web-server-prod":   (None,       "Reserved Instance 1 năm → -30%"),
    "worker-prod":       ("t3.micro", "Downgrade: CPU avg 8.3%"),
    "reporting-server":  ("t3.micro", "Downgrade + schedule stop 18h/ngày"),
    "old-test-server":   ("TERMINATE","Terminate: CPU avg 1.2%"),
}

total_before, total_after = 0, 0
for inst in instances:
    current = inst["monthly_cost_usd"]
    total_before += current
    new_type, action = recommendations.get(inst["name"], (None, ""))
    if new_type == "TERMINATE":    new_cost = 0
    elif new_type:                 new_cost = PRICING[new_type] * 24 * 30
    elif "Reserved" in action:     new_cost = current * 0.7
    else:                          new_cost = current
    total_after += new_cost
    flag = "" if new_type == "TERMINATE" else ("" if new_type else "")
    print(f"{flag} {inst['name']:20s} {inst['type']:12s} CPU:{inst['avg_cpu']:5.1f}%  ${current:.2f} → ${new_cost:.2f}  {action}")

print(f"\nTổng trước : ${total_before:.2f}/tháng")
print(f"Tổng sau   : ${total_after:.2f}/tháng")
print(f"Tiết kiệm  : ${total_before-total_after:.2f}/tháng ({(total_before-total_after)/total_before*100:.0f}%)")
EOF
```

### 4.3 — Viết báo cáo tối ưu

```bash
cat > /tmp/finops-report.md << 'EOF'
# Báo cáo Tối ưu Chi phí Cloud

## Tóm tắt
- Chi phí hiện tại: ~$150/tháng
- Tiết kiệm đề xuất: ~$70/tháng (47%)

## Hành động ưu tiên cao

| Tài nguyên | Hành động | Tiết kiệm/tháng |
|-----------|-----------|----------------|
| old-test-server (t3.medium) | Terminate | $30 |
| reporting-server (t3.xlarge) | Downgrade + schedule stop | $35 |
| worker-prod (t3.large) | Downgrade → t3.micro | $18 |

## Hành động trung hạn
- web-server-prod: Reserved Instance 1 năm → -30%
- Thiết lập Auto Scaling để scale-in ngoài giờ cao điểm
EOF

echo " Báo cáo: /tmp/finops-report.md"
cat /tmp/finops-report.md
```

---

## Câu hỏi

1. Trước khi terminate `old-test-server`, quy trình cần làm là gì?
2. Reserved Instance và Savings Plans khác nhau thế nào?
3. Làm sao tự động hóa việc phát hiện idle resources trong production?

---

##  Bài tập

> Hoàn thành phần thực hành trên trước khi làm bài tập này.

**Yêu cầu:** `api-server-prod` có CPU trung bình 78.2% — đây là server **đang dùng cao**, không nên downsize. Thay vào đó, đề xuất tối ưu chi phí theo hướng khác.

Thêm vào `/tmp/finops-report.md` một section mới:

```
## Đề xuất bổ sung: api-server-prod

- Instance type hiện tại: t3.large (CPU avg: 78.2%)
- Không nên downsize — đang chịu tải cao
- Đề xuất: [Chọn 1 trong: Reserved Instance 1 năm / Savings Plans / Schedule scale-down off-peak]
- Tiết kiệm ước tính: [tính toán % tiết kiệm tương ứng]
- Rủi ro: [mô tả rủi ro của đề xuất đã chọn]
```

**Gợi ý khi bí:**
- Reserved Instance 1 năm → tiết kiệm ~30% (nhưng cần cam kết 1 năm)
- Savings Plans → linh hoạt hơn RI, tiết kiệm ~20-28%
- `api-server-prod` monthly cost: $59.90 → tính tiết kiệm từ đây

> Nhấn **Check** khi hoàn thành.
