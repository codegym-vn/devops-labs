# Lab 34: Ký Số Và Xác Thực Docker Image Với Cosign

Trong quy trình DevSecOps hoàn chỉnh, việc quét lỗ hổng mã nguồn (SAST), phụ thuộc (SCA) và hình ảnh container (Trivy) giúp đảm bảo phần mềm an toàn tại thời điểm biên dịch. Tuy nhiên, sau khi Image được đẩy lên Container Registry (Docker Hub, AWS ECR, Harbor), một câu hỏi an ninh cốt tử được đặt ra:

**Làm sao để cụm Kubernetes hoặc máy chủ Production chắc chắn rằng Container Image chuẩn bị được triển khai chính là bản nguyên gốc đã vượt qua toàn bộ các bài kiểm tra bảo mật, mà không bị tin tặc sửa đổi, đánh tráo hoặc chèn mã độc (Supply Chain Tampering Attack)?**

Dự án mã nguồn mở **Sigstore Cosign** (thuộc Linux Foundation và OpenSSF) ra đời để giải quyết bài toán này thông qua cơ chế ký số và xác thực chữ ký mật mã cho các thành phần OCI Artifact.

---

## 1. Mô Hình Ký Số Và Xác Thực Container Trong DevSecOps

```
┌────────────────────────────────────────────────────────────────────────┐
│                        SIGSTORE COSIGN PIPELINE                        │
├──────────────────────────┬────────────────────────┬────────────────────┤
│       1. BUILD & SIGN    │      2. OCI REGISTRY   │    3. VERIFY & RUN │
├──────────────────────────┼────────────────────────┼────────────────────┤
│ • Build Docker Image     │ • Lưu trữ Image        │ • Kubernetes Node  │
│ • Trivy Gate Passed      │ • Lưu trữ Chữ ký (.sig)│ • K8s Admission Ctrl│
│ • Cosign sign với        │ • Lưu trữ SBOM đính kèm│ • Cosign verify với│
│   Private Key bí mật     │   trên cùng Manifest   │   Public Key       │
└──────────────────────────┴────────────────────────┴────────────────────┘
```

---

## 2. Mục Tiêu Bạn Cần Đạt Được Trong Bài Lab Này

1. **Khởi tạo hạ tầng ký số:** Khởi chạy kho lưu trữ OCI Registry cục bộ, cài đặt công cụ Cosign CLI và tạo lập cặp khóa mật mã bất đối xứng.
2. **Ký số hình ảnh vùng chứa:** Đóng gói ứng dụng mẫu, đẩy lên Registry và thực thi ký số lên mã băm bất biến (Digest) của Image.
3. **Xác thực chữ ký và kiểm chứng chống giả mạo:** Sử dụng khóa công khai để xác thực tính toàn vẹn và chứng minh Cosign chặn đứng các Image bị can thiệp trái phép.
4. **Đính kèm danh mục SBOM và xây dựng Deployment Gate:** Nhúng danh mục linh kiện phần mềm vào Image Manifest và thiết lập script kiểm soát triển khai tự động.

Nhấn **Next** để bắt đầu bước đầu tiên!
