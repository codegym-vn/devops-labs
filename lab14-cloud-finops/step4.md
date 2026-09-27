# Bước 4: Phát hiện tài nguyên idle và lập báo cáo tối ưu

## Lý thuyết: Right-sizing

**Right-sizing** là việc điều chỉnh instance type cho phù hợp với workload thực tế:

```
Hiện tại: t3.xlarge ($0.166/giờ) — CPU avg 3%
   ↓
Sau right-size: t3.micro ($0.010/giờ) — tiết kiệm $111/tháng
```

**Các hình thức tối ưu chi phí:**
| Cách | Tiết kiệm | Rủi ro |
|------|-----------|--------|
| Right-sizing | 20-50% | Cần test kỹ |
| Schedule stop (ngoài giờ) | 60-70% | Chỉ áp dụng non-prod |
| Reserved Instances (1 năm) | ~30% | Cam kết dài hạn |
| Spot Instances | 60-90% | Có thể bị interrupt |

---

## Thử thách thực hành

### 4.1 — Phân tích tài nguyên idle

```bash
echo "=== Phân tích Utilization 5 EC2 Instances ==="
python3 /opt/lab-data/find-idle-resources.py \
  --metrics /opt/lab-data/resource-utilization.json \
  --cpu-threshold 30
```

### 4.2 — Tính chi phí tiết kiệm chi tiết

```bash
python3 << 'PYEOF'
import json

PRICING = {"t3.micro":0.0104,"t3.small":0.0208,"t3.medium":0.0416,"t3.large":0.0832,"t3.xlarge":0.1664}

with open("/opt/lab-data/resource-utilization.json") as f:
    instances = json.load(f)

print("\n=== BÁO CÁO TỐI ƯU CHI PHÍ ===\n")
total_current = 0; total_after = 0

recommendations = [
    ("api-server-prod",   None,         "Giữ nguyên — utilization tốt (78%)"),
    ("web-server-prod",   None,         "Xem xét Reserved Instance 1 năm → tiết kiệm 30%"),
    ("worker-prod",       "t3.micro",   "Downgrade: CPU avg chỉ 8.3%"),
    ("reporting-server",  "t3.micro",   "Downgrade + Schedule stop 18h/ngày"),
    ("old-test-server",   "TERMINATE",  "Terminate ngay: CPU 1.2%, không có giá trị"),
]

for inst in instances:
    current_cost = inst["monthly_cost_usd"]
    total_current += current_cost
    rec = next((r for r in recommendations if r[0] == inst["name"]), None)
    if rec:
        _, new_type, action = rec
        if new_type == "TERMINATE":
            new_cost = 0
        elif new_type:
            new_cost = PRICING.get(new_type, 0) * 24 * 30
        else:
            new_cost = current_cost * 0.7 if "Reserved" in action else current_cost
        savings = current_cost - new_cost
        total_after += new_cost
        flag = "🔴" if new_type == "TERMINATE" else ("🟡" if new_type else "🟢")
        print(f"  {flag} {inst['name']}")
        print(f"     Hiện tại : {inst['type']} — ${current_cost:.2f}/tháng (CPU: {inst['avg_cpu']}%)")
        print(f"     Hành động: {action}")
        if savings > 0:
            print(f"     Tiết kiệm: ${savings:.2f}/tháng")
        print()

print(f"  Chi phí hiện tại  : ${total_current:.2f}/tháng")
print(f"  Chi phí sau tối ưu: ${total_after:.2f}/tháng")
print(f"  Tổng tiết kiệm    : ${total_current-total_after:.2f}/tháng ({(total_current-total_after)/total_current*100:.0f}%)")
PYEOF
```

### 4.3 — Viết báo cáo tối ưu chi phí

```bash
cat > /tmp/finops-report.md << 'REPORT'
# Báo cáo Tối ưu Chi phí Cloud — Tháng 9/2024

## Tóm tắt điều hành

Sau phân tích 5 EC2 instances và Cost & Usage Report 30 ngày:
- **Tổng chi phí hiện tại**: ~$150/tháng
- **Tiết kiệm đề xuất**: ~$70/tháng (47%)
- **Thời gian thực hiện**: 1 tuần

## Hành động ưu tiên cao

| # | Tài nguyên | Hành động | Tiết kiệm/tháng |
|---|-----------|-----------|-----------------|
| 1 | old-test-server (t3.medium) | Terminate ngay | $30 |
| 2 | reporting-server (t3.xlarge) | Downgrade → t3.micro + schedule stop | $35 |
| 3 | worker-prod (t3.large) | Downgrade → t3.micro | $18 |

## Hành động trung hạn

- web-server-prod: Mua Reserved Instance 1 năm → tiết kiệm 30%
- Thiết lập Auto Scaling để tự scale-in ngoài giờ cao điểm

## Kết luận

Tổng tiết kiệm **$70/tháng ($840/năm)** với rủi ro thấp.
REPORT

echo "✅ Báo cáo đã lưu tại /tmp/finops-report.md"
cat /tmp/finops-report.md
```

---

## Câu hỏi kiểm tra hiểu biết

1. Nếu `old-test-server` vẫn đang được dùng bởi một developer nào đó, quy trình trước khi terminate nên là gì?
2. **Reserved Instance** và **Savings Plans** khác nhau như thế nào? Khi nào dùng loại nào?
3. Bạn sẽ **tự động hóa** việc phát hiện idle resources như thế nào trong môi trường production?
