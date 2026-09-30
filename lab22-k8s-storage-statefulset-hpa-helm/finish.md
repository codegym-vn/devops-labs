# Xin Chúc Mừng! Bạn Đã Hoàn Thành Xuất Sắc Lab 22!

Bạn đã chính thức làm chủ các kiến trúc phức tạp và mạnh mẽ nhất trong hệ sinh thái Kubernetes: cấp phát động lưu trữ bền vững với StorageClass & PVC, quản trị khối lượng công việc cơ sở dữ liệu có trạng thái với StatefulSet & Headless Service, thiết lập cơ chế tự động co giãn theo tải với HPA, và chuyên nghiệp hóa quy trình đóng gói phân phối ứng dụng với Helm Chart.

---

## 1. Bảng Tra Cứu Nhanh (Kubernetes Advanced Cheat Sheet)

```
┌─────────────────────────────────────────────────────────────┐
│             K8S ADVANCED & HELM QUICK REFERENCE             │
├─────────────────────────────────────────────────────────────┤
│ 1. Quản lý lưu trữ động (Storage):                          │
│    kubectl get sc,pv,pvc                                    │
│    kubectl describe pvc <name>                              │
│                                                             │
│ 2. Khối lượng công việc có trạng thái (StatefulSet):        │
│    kubectl get statefulset,pods -l app=<label>              │
│    kubectl scale statefulset <name> --replicas=<count>      │
│                                                             │
│ 3. Tự động co giãn theo tải (HPA):                          │
│    kubectl get hpa                                          │
│    kubectl autoscale deployment <name> --cpu-percent=50     │
│      --min=2 --max=8                                        │
│    kubectl top nodes / kubectl top pods                     │
│                                                             │
│ 4. Quản lý gói ứng dụng (Helm):                             │
│    helm create <chart-name>                                 │
│    helm template <release> <chart-dir>                      │
│    helm install <release> <chart-dir>                       │
│    helm upgrade <release> <chart-dir> --set key=value       │
│    helm history <release>                                   │
│    helm rollback <release> <revision-number>                │
│    helm uninstall <release>                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Lưu Ý Vàng Khi Vận Hành Trong Môi Trường Sản Xuất

1. **Chính sách xóa ổ đĩa của StatefulSet (Reclaim Policy):**
   * Khi bạn xóa một StatefulSet hoặc thu hẹp số lượng bản sao (scale down), Kubernetes **sẽ không bao giờ tự động xóa PVC** liên kết với các Pod đó. Đây là cơ chế an toàn chủ động nhằm bảo vệ dữ liệu nghiệp vụ của bạn không bị mất do thao tác vô ý. Nếu thực sự muốn xóa dữ liệu, bạn phải xóa PVC thủ công!
2. **Chống dao động co giãn (Flapping / Thrashing) trong HPA:**
   * Khi tải tăng đột biến rồi giảm ngay lập tức, HPA có thể liên tục scale-up rồi scale-down tạo ra hiệu ứng dao động. Trong Kubernetes hiện đại, hãy cấu hình `behavior.scaleDown.stabilizationWindowSeconds` (mặc định là 300 giây = 5 phút) để đảm bảo hệ thống giữ ổn định trước khi quyết định tắt bớt Pod.
3. **Quản lý bí mật trong Helm (Helm Secrets):**
   * Tuyệt đối không lưu mật khẩu trần (plaintext passwords) trong tệp `values.yaml` rồi commit lên Git. Hãy sử dụng các giải pháp như `helm-secrets` (kết hợp Mozilla SOPS) hoặc tích hợp với External Secrets Operator để nạp bí mật an toàn từ Vault / AWS Secrets Manager.

---

## 3. Câu Hỏi Trắc Nghiệm Ôn Tập (CKA Interview)

<details>
<summary><b>1. Tại sao lệnh `kubectl top pods` hoặc HPA báo lỗi `<unknown>` trong cột TARGETS?</b></summary>

> **Đáp án:** Có hai nguyên nhân phổ biến:
> 1. Pod template của Deployment chưa được định cấu hình phần `resources.requests.cpu`. HPA không thể tính tỷ lệ phần trăm nếu không có mức sàn tham chiếu.
> 2. Cụm chưa cài đặt hoặc `metrics-server` gặp sự cố không thể thu thập chỉ số CPU/RAM từ Kubelet.
</details>

<details>
<summary><b>2. Khi một Pod trong StatefulSet bị chết và được tạo lại, điều gì đảm bảo nó nhận lại đúng ổ đĩa cũ?</b></summary>

> **Đáp án:** Nhờ cơ chế `volumeClaimTemplates`, tên của PVC được sinh theo quy tắc cố định `<tên-template>-<tên-pod>`. Vì Pod trong StatefulSet luôn giữ nguyên định danh chỉ số (ví dụ `db-1`), Pod mới sinh ra sẽ tự động gắn kết lại đúng PVC `data-db-1` đã tồn tại từ trước.
</details>

<details>
<summary><b>3. Lệnh nào giúp kiểm tra cấu hình biên dịch của Helm Chart mà không tạo bất kỳ tài nguyên nào trên cụm?</b></summary>

> **Đáp án:** Sử dụng lệnh `helm template <tên-release> <thư-mục-chart>` hoặc cờ `helm install --dry-run --debug`. Lệnh này sẽ hiển thị toàn bộ nội dung tệp YAML đã được thay thế biến số từ `values.yaml`.
</details>

---

## 4. Tổng Kết Chuyên Đề Container Orchestration Với Kubernetes

Bạn đã hoàn thành chuỗi 4 bài lab toàn diện về Kubernetes:
* **Lab 19:** Tương tác cụm qua `kubectl`, giải phẫu cấu trúc Kubeconfig và kiểm tra sức khỏe Node.
* **Lab 20:** Đóng gói Pod, thiết lập hạn mức tài nguyên, triển khai Deployment tự phục hồi, nạp ConfigMap/Secret và kiểm tra sức khỏe Probes.
* **Lab 21:** Phân vùng Namespace, cân bằng tải ClusterIP & NodePort Service, điều phối L7 Ingress và phân quyền RBAC.
* **Lab 22:** Cấp phát động StorageClass, cơ sở dữ liệu StatefulSet, tự động co giãn HPA và đóng gói quản trị Helm Chart.

Chúc mừng bạn đã sở hữu trọn vẹn kỹ năng nền tảng vững chắc để tự tin vận hành các hệ thống Kubernetes cấp doanh nghiệp và chinh phục chứng chỉ CKA!
