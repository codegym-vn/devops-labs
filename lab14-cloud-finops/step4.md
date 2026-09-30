# Bước 4: Phát Hiện Tài Nguyên Idle, Đề Xuất Tối Ưu & Thực Thi Bằng AWS CLI

Trong bước cuối cùng, bạn sẽ học cách phân tích dữ liệu hiệu năng thực tế (**Utilization Metrics**) để phát hiện các tài nguyên chạy ngầm lãng phí (**Idle Resources**), tính toán chi phí tiết kiệm và trực tiếp ra lệnh hủy tài nguyên bằng **AWS CLI**.

---

## 1. Lý Thuyết: Chiến Lược Right-Sizing & Vòng Lặp FinOps

* **Right-Sizing:** Điều chỉnh cấu hình máy ảo (Instance Type) về đúng nhu cầu tải thực tế:
  * Ví dụ: Máy ảo `t3.xlarge` ($119.81/tháng) nhưng CPU trung bình chỉ 3.1% → Hạ xuống `t3.small` ($15/tháng) giúp tiết kiệm ngay ~87%!
* **Terminate Idle Resources:** Hủy ngay lập tức các máy chủ thử nghiệm cũ (`old-test-server`) bị bỏ quên nhưng vẫn âm thầm đốt tiền hàng tháng.

| Chiến lược FinOps | Mức tiết kiệm ước tính | Khuyến nghị áp dụng |
|---|---|---|
| **Terminate Idle** | **100%** | Máy chủ dev/test cũ, CPU < 2%, không có traffic |
| **Right-sizing** | **30% – 60%** | Máy chủ thừa vCPU/RAM (CPU < 20%) |
| **Schedule Stop ngoài giờ** | **65% – 70%** | Tự động tắt máy staging/dev từ 19h đến 7h sáng hôm sau |
| **Reserved Instances / Savings Plans** | **30% – 50%** | Máy chủ production chạy liên tục 24/7 (cam kết 1-3 năm) |

---

## 2. Thực Hành

### 4.1 — Phát Hiện Máy Chủ Lãng Phí (CPU < 30%)

Chạy công cụ phân tích hiệu năng để quét toàn bộ 5 máy chủ trong hệ thống:

```bash
python3 /opt/lab-data/find-idle-resources.py \
  --metrics /opt/lab-data/resource-utilization.json \
  --cpu-threshold 30
```{{exec}}

Quan sát terminal: Công cụ sẽ chỉ ra 3 máy chủ có mức tải CPU rất thấp:
1. `worker-prod`: CPU 8.3%
2. `reporting-server`: CPU 3.1%
3. `old-test-server`: CPU 1.2% (Rất lãng phí!)

---

### 4.2 — Lập Báo Cáo Khuyến Nghị Tối Ưu Chi Phí

Tạo báo cáo FinOps tổng hợp gửi ban quản trị tại `/tmp/finops-report.md`:

```bash
cat << 'EOF' > /tmp/finops-report.md
# BÁO CÁO TỐI ƯU HÓA CHI PHÍ ĐÁM MÂY (FINOPS REPORT)

## 1. Đánh giá hiện trạng
- Tổng số máy chủ theo dõi: 5 EC2 instances
- Tổng chi phí hiện tại: ~$290/tháng
- Tỷ lệ tài nguyên lãng phí (CPU < 30%): 3/5 instances (60%)

## 2. Hành động ưu tiên cao (Khắc phục ngay)
| Tên Instance | Cấu hình | Tải CPU | Hành động đề xuất | Tiết kiệm/tháng |
|---|---|---|---|---|
| **old-test-server** | t3.medium | 1.2% | **TERMINATE (Hủy máy ảo)** | ~$29.95 |
| **reporting-server**| t3.xlarge | 3.1% | Right-size xuống t3.small + Lập lịch Stop ngoài giờ | ~$95.00 |
| **worker-prod**     | t3.large  | 8.3% | Right-size xuống t3.medium | ~$29.95 |

👉 **Tổng mức tiết kiệm ước tính:** ~$154.90/tháng (~53% ngân sách compute).
EOF

cat /tmp/finops-report.md
```{{exec}}

---

### 4.3 — Thực Thi Hành Động FinOps Bằng AWS CLI: Hủy Máy Chủ Idle

Sau khi có khuyến nghị từ báo cáo, kỹ sư FinOps phối hợp với DevOps thực thi ngay lệnh hủy máy chủ `old-test-server` trên AWS:

```bash
source /tmp/lab-env.sh

echo "Đang gửi lệnh hủy máy ảo old-test-server: $SRV_TEST..."
aws ec2 terminate-instances --instance-ids $SRV_TEST

echo "✅ Đã hủy máy ảo old-test-server thành công để chấm dứt lãng phí chi phí!"
```{{exec}}

Kiểm tra trạng thái để xác nhận máy ảo đã chuyển sang `shutting-down` hoặc `terminated`:

```bash
aws ec2 describe-instances --instance-ids $SRV_TEST --query 'Reservations[0].Instances[0].[InstanceId, State.Name]' --output table
```{{exec}}

---

## 3. Bài Tập Thử Thách

**Yêu cầu:** Máy chủ `api-server-prod` có mức sử dụng CPU trung bình **78.2%** (đang chịu tải rất cao). Hãy bổ sung vào cuối file `/tmp/finops-report.md` đề xuất tối ưu phù hợp cho máy chủ này (chọn giải pháp cam kết dài hạn **Reserved Instances** để giảm 30% chi phí thay vì hạ cấu hình).

Chạy lệnh bổ sung sau:

```bash
cat << 'EOF' >> /tmp/finops-report.md

## 3. Đề xuất bổ sung: api-server-prod
- Instance type: t3.large (CPU avg: 78.2% - đang chịu tải cao, KHÔNG hạ cấu hình).
- Đề xuất: Mua Reserved Instance cam kết 1 năm trả trước để giảm 30% chi phí.
- Tiết kiệm ước tính: ~$17.97/tháng mà không ảnh hưởng hiệu năng hệ thống.
EOF

echo "✅ Đã cập nhật đề xuất cho api-server-prod vào báo cáo!"
```{{exec}}

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và hoàn thành toàn bộ bài lab!
