# Xin Chúc Mừng! Bạn Đã Hoàn Thành Xuất Sắc Lab 20!

Bạn đã làm chủ toàn bộ chu trình đóng gói và vận hành khối lượng công việc cốt lõi trong Kubernetes: từ việc thiết lập giới hạn tài nguyên cho Pod, mở rộng quy mô và tự phục hồi với Deployment, quản trị cấu hình động và bảo mật với ConfigMap/Secret, cho đến việc thiết lập cơ chế giám sát tự động với Liveness & Readiness Probes.

---

## 1. Tổng Kết Các Kiến Thức Cốt Lõi Đã Đạt Được

```
┌─────────────────────────────────────────────────────────────┐
│               KUBERNETES WORKLOAD CHEAT SHEET               │
├─────────────────────────────────────────────────────────────┤
│ 1. Sinh khung YAML cực nhanh (CKA Golden Tip):              │
│    kubectl run my-pod --image=nginx --dry-run=client        │
│      -o yaml > pod.yaml                                     │
│    kubectl create deployment my-dep --image=nginx           │
│      --replicas=3 --dry-run=client -o yaml > dep.yaml       │
│                                                             │
│ 2. Quản lý bản sao và quy mô (Scaling):                     │
│    kubectl scale deployment <name> --replicas=<count>       │
│    kubectl rollout status deployment/<name>                 │
│                                                             │
│ 3. Tạo ConfigMap & Secret nhanh:                            │
│    kubectl create configmap <name> --from-literal=K=V       │
│    kubectl create secret generic <name> --from-literal=K=V  │
│                                                             │
│ 4. Nguyên tắc thiết lập Health Check Probes:                │
│    - livenessProbe: Restart khi treo (Deadlock/Crash)       │
│    - readinessProbe: Tách khỏi Service khi chưa nạp xong   │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Lưu Ý Vàng Khi Vận Hành Trong Môi Trường Sản Xuất

1. **Nguy hiểm chết người khi cấu hình Liveness Probe sai:**
   * Tuyệt đối không trỏ Liveness Probe vào các endpoint kiểm tra phụ thuộc bên ngoài (ví dụ: database healthcheck). Nếu Database bị quá tải phản hồi chậm, Liveness Probe sẽ đồng loạt báo lỗi khiến Kubernetes restart toàn bộ các Pod ứng dụng cùng lúc (hiệu ứng tuyết lở - Cascading Failure). Hãy để việc kiểm tra phụ thuộc đó cho Readiness Probe!
2. **Luôn đặt Resources Requests & Limits:**
   * Nếu không đặt `requests`, Pod có thể bị xếp lên một Node sắp hết tài nguyên dẫn đến chèn ép CPU/RAM.
   * Nếu không đặt `limits`, một lỗi rò rỉ bộ nhớ (memory leak) đơn lẻ có thể làm treo cả máy chủ vật lý của cụm.
3. **Quản lý Secrets nâng cao:**
   * Trong thực tế doanh nghiệp lớn, Secret thường được mã hóa tự động ở tầng etcd (Encryption at Rest) hoặc đồng bộ từ các kho bảo mật chuyên dụng như HashiCorp Vault, AWS Secrets Manager hoặc Azure Key Vault thông qua Secrets Store CSI Driver.

---

## 3. Câu Hỏi Trắc Nghiệm Ôn Tập (CKA Interview)

<details>
<summary><b>1. Điều gì xảy ra khi một container sử dụng bộ nhớ RAM vượt quá ngưỡng limits.memory đã khai báo?</b></summary>

> **Đáp án:** Tiến trình sẽ bị nhân Linux OOM-Killer tiêu diệt ngay lập tức với mã lỗi thoát là `137` (OOMKilled - Out Of Memory). Kubernetes sẽ tự động khởi động lại container theo chính sách `restartPolicy`. Ngược lại, nếu vượt quá `limits.cpu`, container chỉ bị bóp băng thông CPU (throttling) chứ không bị kill.
</details>

<details>
<summary><b>2. Sự khác biệt cơ bản giữa Liveness Probe và Readiness Probe khi kiểm tra thất bại là gì?</b></summary>

> **Đáp án:**
> * Khi **Liveness Probe** thất bại quá ngưỡng `failureThreshold`, Kubelet sẽ **khởi động lại (restart)** container.
> * Khi **Readiness Probe** thất bại, Kubelet sẽ **gỡ Pod ra khỏi Endpoints của Service** để ngừng nhận traffic mạng, **tuyệt đối không restart** container.
</details>

<details>
<summary><b>3. Tại sao trong môi trường Production không nên triển khai ứng dụng bằng Bare Pod (Pod đơn lẻ)?</b></summary>

> **Đáp án:** Vì Bare Pod không được gắn với bất kỳ Controller nào (như ReplicaSet, Deployment). Nếu máy chủ vật lý chạy Pod đó bị hỏng hoặc tiến trình chết không thể tự phục hồi, Kubernetes sẽ không tự động tạo lại Pod ở một node khác, dẫn đến gián đoạn dịch vụ kéo dài.
</details>

---

## 4. Bài Lab Tiếp Theo

Trong bài lab tiếp theo (**Lab 21**), chúng ta sẽ khám phá tầng mạng kết nối dịch vụ trong Kubernetes: **ClusterIP, NodePort, LoadBalancer Services và Ingress Controller** để đưa ứng dụng từ mạng nội bộ Pod ra thế giới bên ngoài an toàn và hiệu năng cao!
