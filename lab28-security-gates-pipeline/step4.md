# Bước 4: Tích Hợp Pipeline Hoàn Chỉnh & Thử Nghiệm Cơ Chế Chặn Release

Trong bước cuối cùng, bạn sẽ liên kết cả 3 Security Gates vào một kịch bản điều phối CI/CD hoàn chỉnh, áp dụng nguyên tắc **Fail-Fast** và thử nghiệm tình huống thực tế khi một nhà phát triển vô tình đưa mã nguồn chứa lỗ hổng vào hệ thống.

---

## 1. Kịch Bản Điều Phối CI/CD Liên Hoàn

```
                    ┌────────────────────────────┐
                    │      run-full-pipeline.sh  │
                    └─────────────┬──────────────┘
                                  │
         ┌────────────────────────┼────────────────────────┐
         ▼                        ▼                        ▼
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│      GATE 1      │     │      GATE 2      │     │      GATE 3      │
│  Secret Scanning │────►│  SCA Dependency  │────►│  Container Image │
│    (Gitleaks)    │     │     (Trivy fs)   │     │  (Trivy image)   │
└──────────────────┘     └──────────────────┘     └────────┬─────────┘
                                                           │
                                                           ▼ (Chỉ khi cả 3 PASSED)
                                                  ┌──────────────────┐
                                                  │ DEPLOY TO PROD   │
                                                  │ (Release Success)│
                                                  └──────────────────┘
```

Nếu bất kỳ Gate nào bị vi phạm, pipeline sẽ ngay lập tức dừng lại, từ chối thực hiện các bước tiếp theo để bảo vệ an toàn cho hệ thống.

---

## 2. Các Bước Thực Hiện

### 2.1 — Tạo script điều phối Pipeline hoàn chỉnh

Tạo tệp `run-full-pipeline.sh`:

```bash
cd /root/security-gate-lab
cat << 'EOF' > run-full-pipeline.sh
#!/bin/bash
set -e

echo "=========================================================="
echo "      BAT DAU QUY TRINH DEVSECOPS CI/CD PIPELINE          "
echo "=========================================================="

# 1. Kich hoat Gate 1
if ! ./gate1-secret-scan.sh; then
  echo ""
  echo ">>> [PIPELINE BLOCKED] Bi chan ngay tai GATE 1 (Secret Leak)!"
  exit 1
fi

# 2. Kich hoat Gate 2
if ! ./gate2-sca-scan.sh; then
  echo ""
  echo ">>> [PIPELINE BLOCKED] Bi chan ngay tai GATE 2 (SCA Dependencies)!"
  exit 1
fi

# 3. Kich hoat Gate 3
if ! ./gate3-image-scan.sh; then
  echo ""
  echo ">>> [PIPELINE BLOCKED] Bi chan ngay tai GATE 3 (Container Image)!"
  exit 1
fi

# 4. Khi ca 3 Gate deu Passed -> Cho phep Deploy
echo ""
echo "=========================================================="
echo ">>> [CONGRATULATIONS] TAT CA CANG SECURITY GATES DEU PASSED!"
echo ">>> KICH HOAT TRIEN KHAI RELEASE LEN PRODUCTION THANH CONG."
echo "=========================================================="
exit 0
EOF

chmod +x run-full-pipeline.sh
```{{exec}}

---

### 2.2 — Chạy thử nghiệm Pipeline trên mã nguồn sạch

Thực thi pipeline trên mã nguồn hiện tại:

```bash
./run-full-pipeline.sh
```{{exec}}

Kết quả: Toàn bộ Gate 1, Gate 2 và Gate 3 đều vượt qua thành công, thông báo `[CONGRATULATIONS] TAT CA CANG SECURITY GATES DEU PASSED!` xuất hiện.

---

### 2.3 — Thử nghiệm cơ chế chặn Release khi cố tình đưa Secret vào code

Giả lập tình huống một lập trình viên vô tình tạo tệp chứa khóa bí mật AWS:

```bash
cat << 'EOF' > aws_leak.env
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
EOF
```{{exec}}

Chạy lại toàn bộ pipeline:

```bash
./run-full-pipeline.sh
```{{exec}}

Quan sát phản ứng của hệ thống:
* **Gate 1** lập tức phát hiện khóa `AKIAIOSFODNN7EXAMPLE` và phát tín hiệu thất bại.
* Pipeline dừng ngay lập tức: `>>> [PIPELINE BLOCKED] Bi chan ngay tai GATE 1 (Secret Leak)!`.
* Gate 2, Gate 3 và khâu Deploy hoàn toàn không được kích hoạt, ngăn chặn 100% rủi ro đưa mã lỗi lên Production.

---

### 2.4 — Khắc phục lỗi và khôi phục trạng thái chuẩn

Xóa tệp chứa secret bị rò rỉ:

```bash
rm -f aws_leak.env
```{{exec}}

Chạy lại pipeline để nghiệm thu:

```bash
./run-full-pipeline.sh
```{{exec}}

Hệ thống trở lại trạng thái xanh tuyệt đối. Bạn đã làm chủ hoàn toàn kỹ thuật thiết kế Security Gates đa tầng cho quy trình DevSecOps chuyên nghiệp.

Nhấn **Check** để hoàn thành Bước 4!
