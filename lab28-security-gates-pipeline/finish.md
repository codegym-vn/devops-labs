# Hoàn Thành Bài Lab 28: Xây Dựng Security Gates Trong CI/CD Pipeline

Xin chúc mừng! Bạn đã hoàn thành xuất sắc bài thực hành xây dựng các cổng kiểm soát an ninh đa tầng (**Security Gates**) cho chu trình DevSecOps hiện đại.

---

## 1. Tổng Kết Các Kỹ Năng Đã Đạt Được

1. **Thiết Lập Kiến Trúc Security Gates Đa Tầng:**
   * Gate 1: Ngăn chặn rò rỉ bí mật với Gitleaks (Secret Scanning).
   * Gate 2: Phân tích thành phần phần mềm SCA với Trivy filesystem (Dependencies CVE).
   * Gate 3: Quét lỗ hổng nhân hệ điều hành và gói container với Trivy image (Container Security).

2. **Áp Dụng Nguyên Tắc Fail-Fast Trong Pipeline:**
   * Dừng pipeline ngay tại cổng đầu tiên khi phát hiện vi phạm, tiết kiệm tối đa tài nguyên tính toán và thời gian của runner.
   * Ngăn chặn triệt để mã độc hoặc thông tin mật bị đóng gói và phát hành ra môi trường Production.

3. **Cấu Hình Ngưỡng Chặn Chuẩn Doanh Nghiệp (Threshold Control):**
   * Sử dụng các cờ `--severity CRITICAL,HIGH` kết hợp `--exit-code 1` để phân tách giữa các lỗi nguy cấp cần chặn đứng và các cảnh báo phụ mức Low/Medium.

---

## 2. Tham Khảo Cấu Hình GitHub Actions Workflow Hoàn Chỉnh

Trong dự án thực tế trên GitHub, toàn bộ các cổng này được viết thành các Job phụ thuộc nhau trong tệp `.github/workflows/security-gates.yml`:

```yaml
name: DevSecOps Security Gates

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  gate-1-secrets:
    name: Gate 1 - Secret Scanning
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  gate-2-sca:
    name: Gate 2 - SCA Dependency Scan
    needs: gate-1-secrets
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          severity: 'CRITICAL,HIGH'
          exit-code: '1'

  gate-3-container:
    name: Gate 3 - Container Image Scan
    needs: gate-2-sca
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build Docker Image
        run: docker build -t my-app:${{ github.sha }} .
      - uses: aquasecurity/trivy-action@master
        with:
          image-ref: my-app:${{ github.sha }}
          severity: 'CRITICAL,HIGH'
          exit-code: '1'

  deploy:
    name: Deploy to Production
    needs: gate-3-container
    runs-on: ubuntu-latest
    steps:
      - run: echo "All Security Gates Passed. Deploying application..."
```

---

Bạn có thể tiếp tục tự do khám phá môi trường hoặc đóng kịch bản bài học. Chúc bạn ứng dụng thành công các nguyên lý DevSecOps này vào các hệ thống doanh nghiệp thực tế!
