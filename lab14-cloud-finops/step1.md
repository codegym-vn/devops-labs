# Bước 1: Gắn Cost Allocation Tags Lên Tài Nguyên Cloud Bằng AWS CLI

Trong bước đầu tiên, bạn sẽ sử dụng **AWS CLI** để áp dụng chiến lược gắn nhãn định danh chi phí (**Cost Allocation Tags**) lên các máy ảo EC2 trong công ty, giải quyết bài toán: *"Chi phí đám mây tháng này thuộc về ai và dùng cho mục đích gì?"*

---

## 1. Lý Thuyết: Chiến Lược Gắn Tag Phân Bổ Chi Phí (FinOps Tagging)

Một máy ảo EC2 không gắn tag sẽ trở thành một **"hố đen chi phí"**: Không ai dám tắt vì sợ ảnh hưởng hệ thống, nhưng cũng không team nào chịu thanh toán tiền.

Chuẩn bộ Tag phân bổ chi phí bắt buộc trong doanh nghiệp:

| Tag Key | Ý nghĩa FinOps | Ví dụ giá trị |
|---|---|---|
| **`Project`** | Tên sản phẩm / Dự án kinh doanh | `e-commerce`, `data-platform`, `internal-tools` |
| **`Environment`** | Môi trường triển khai | `production`, `staging`, `development` |
| **`Owner`** | Đội ngũ kỹ thuật chịu trách nhiệm | `team-backend`, `team-frontend`, `team-data` |
| **`CostCenter`** | Mã trung tâm chi phí để kế toán khấu trừ | `CC-001`, `CC-002`, `CC-003` |

---

## 2. Thực Hành

Tải danh sách các Instance ID đã được khởi tạo sẵn trong LocalStack:

```bash
source /tmp/lab-env.sh
echo "API Server ID: $SRV_API"
echo "Web Server ID: $SRV_WEB"
echo "Worker Server ID: $SRV_WORKER"
echo "Reporting Server ID: $SRV_REPORT"
echo "Old Test Server ID: $SRV_TEST"
```{{exec}}

---

### 1.1 — Gắn Cost Allocation Tags Cho Cụm Dự Án E-Commerce

Sử dụng lệnh `aws ec2 create-tags` để gắn đồng thời 4 nhãn chuẩn cho 2 máy chủ của dự án `e-commerce`:

```bash
# 1. Gắn Tags cho API Server
aws ec2 create-tags \
  --resources $SRV_API \
  --tags \
    Key=Project,Value=e-commerce \
    Key=Environment,Value=production \
    Key=Owner,Value=team-backend \
    Key=CostCenter,Value=CC-001

# 2. Gắn Tags cho Web Server
aws ec2 create-tags \
  --resources $SRV_WEB \
  --tags \
    Key=Project,Value=e-commerce \
    Key=Environment,Value=production \
    Key=Owner,Value=team-frontend \
    Key=CostCenter,Value=CC-001

echo "✅ Đã gắn Tags thành công cho cụm dự án e-commerce!"
```{{exec}}

---

### 1.2 — Gắn Tags Cho Cụm Data Platform & Reporting

Tiếp tục gắn nhãn cho các máy chủ xử lý dữ liệu và báo cáo nội bộ:

```bash
# 1. Gắn Tags cho Worker Server
aws ec2 create-tags \
  --resources $SRV_WORKER \
  --tags \
    Key=Project,Value=data-platform \
    Key=Environment,Value=production \
    Key=Owner,Value=team-data \
    Key=CostCenter,Value=CC-002

# 2. Gắn Tags cho Reporting Server
aws ec2 create-tags \
  --resources $SRV_REPORT \
  --tags \
    Key=Project,Value=internal-tools \
    Key=Environment,Value=staging \
    Key=Owner,Value=team-devops \
    Key=CostCenter,Value=CC-003

echo "✅ Đã gắn Tags cho Data Platform và Reporting Server!"
```{{exec}}

---

### 1.3 — Kiểm Tra Tính Tuân Thủ (Tag Compliance) Bằng AWS CLI Filters

Sử dụng cờ `--filters` để lọc và nhóm các máy chủ theo từng dự án:

```bash
echo "=== Danh sách máy chủ thuộc Project: e-commerce ==="
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=e-commerce" \
  --query "Reservations[].Instances[].[Tags[?Key=='Name'].Value | [0], InstanceId, Tags[?Key=='Owner'].Value | [0], Tags[?Key=='CostCenter'].Value | [0]]" \
  --output table
```{{exec}}

---

## 3. Bài Tập Thử Thách

> [!TIP]
> Máy chủ `old-test-server` (`$SRV_TEST`) hiện đang thiếu nhãn định danh và có nguy cơ bị cảnh báo vi phạm chính sách Tagging!

**Yêu cầu:** Hãy dùng lệnh `aws ec2 create-tags` để gắn đầy đủ 4 tag chuẩn cho máy chủ `$SRV_TEST`:
* `Project`: `internal-tools`
* `Environment`: `development`
* `Owner`: `team-devops`
* `CostCenter`: `CC-003`

**Gợi ý lệnh:**
* Tham khảo cú pháp ở mục **1.2**, thay đổi `--resources $SRV_TEST`.

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
