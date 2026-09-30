# Xin Chúc Mừng! Bạn Đã Hoàn Thành Xuất Sắc Lab 21!

Bạn đã chinh phục thành công các trụ cột quan trọng nhất về kiến trúc mạng và an ninh trong Kubernetes: phân tách môi trường với Namespace, cân bằng tải tầng 4 với ClusterIP và NodePort Service, điều phối lưu lượng tầng 7 linh hoạt với Ingress, và thiết lập ma trận bảo mật đặc quyền tối thiểu với RBAC.

---

## 1. Bảng Tổng Hợp Lệnh Nhanh (Kubernetes Networking & RBAC Cheat Sheet)

```
┌─────────────────────────────────────────────────────────────┐
│             K8S NETWORKING & RBAC QUICK REFERENCE           │
├─────────────────────────────────────────────────────────────┤
│ 1. Không gian tên (Namespaces):                             │
│    kubectl create ns <name>                                 │
│    kubectl get pods -n <name>                               │
│    kubectl get pods -A (xem tất cả namespaces)              │
│                                                             │
│ 2. Dịch vụ mạng (Services):                                 │
│    kubectl expose deployment <name> --port=80 --target-port │
│      =8080 --type=ClusterIP                                 │
│    kubectl get svc,ep -o wide                               │
│                                                             │
│ 3. Điều phối lối vào (Ingress):                             │
│    kubectl get ingress                                      │
│    kubectl describe ingress <name>                          │
│                                                             │
│ 4. Kiểm soát truy cập (RBAC):                               │
│    kubectl create sa <name> -n <ns>                         │
│    kubectl create role <name> --verb=get,list               │
│      --resource=pods -n <ns>                                │
│    kubectl create rolebinding <name> --role=<role>          │
│      --serviceaccount=<ns>:<sa> -n <ns>                     │
│    kubectl auth can-i <verb> <res> --as=... -n <ns>         │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Lưu Ý Vàng Khi Vận Hành Trong Môi Trường Sản Xuất

1. **Luôn sử dụng Namespace kết hợp với NetworkPolicy:**
   * Mặc định trong Kubernetes, Pod ở bất kỳ Namespace nào cũng có thể gửi gói tin mạng sang Pod ở Namespace khác (Flat Network). Để cách ly hoàn toàn môi trường Production khỏi Staging hay Dev, bạn cần áp dụng `NetworkPolicy` để chặn lưu lượng liên Namespace ở tầng mạng.
2. **Quy tắc phân quyền Principle of Least Privilege:**
   * Không bao giờ lạm dụng `ClusterRoleBinding` với `cluster-admin` cho các tiến trình tự động (CI/CD pipelines, monitoring agents). Chỉ cấp đúng những tài nguyên (resources) và hành động (verbs) tối thiểu cần thiết trong đúng Namespace đó thông qua `RoleBinding`.
3. **Chiến lược Ingress thay thế NodePort:**
   * Hạn chế tối đa việc mở cổng NodePort ra ngoài Internet trong môi trường thực tế vì nó làm lộ dải cổng máy chủ và phân tán lưu lượng. Hãy tập trung toàn bộ lưu lượng qua một cổng Ingress duy nhất (cổng 80/443) có gắn tường lửa ứng dụng (WAF) và quản lý chứng chỉ SSL tự động qua `cert-manager`.

---

## 3. Câu Hỏi Trắc Nghiệm Ôn Tập (CKA Interview)

<details>
<summary><b>1. Sự khác biệt cốt lõi giữa Role và ClusterRole trong Kubernetes là gì?</b></summary>

> **Đáp án:**
> * **Role** chỉ có hiệu lực bên trong **một Namespace cụ thể** và chỉ quản lý các tài nguyên có phạm vi namespace (như Pods, Deployments, Services, ConfigMaps).
> * **ClusterRole** có phạm vi trên **toàn bộ cụm Kubernetes**, quản lý được cả các tài nguyên phi namespace (như Nodes, PersistentVolumes, Namespaces) hoặc có thể được gắn kết bằng RoleBinding để tái sử dụng mẫu quyền trong từng namespace.
</details>

<details>
<summary><b>2. Khi một Pod gửi request tới tên miền `my-service`, cơ chế nào giúp phân giải địa chỉ IP?</b></summary>

> **Đáp án:** Thành phần **CoreDNS** (chạy bên trong namespace `kube-system`) sẽ tự động bổ sung hậu tố tìm kiếm theo tệp `/etc/resolv.conf` của Pod để hoàn thiện tên miền FQDN `my-service.<current-namespace>.svc.cluster.local` và trả về địa chỉ IP ảo tĩnh (ClusterIP) của Service.
</details>

<details>
<summary><b>3. Lệnh nào giúp kiểm tra nhanh xem một ServiceAccount có được phép thực hiện hành động hay không mà không cần tạo Pod chạy thử?</b></summary>

> **Đáp án:** Sử dụng công cụ `kubectl auth can-i <hành-động> <tài-nguyên> --as=system:serviceaccount:<namespace>:<tên-sa> -n <namespace>`. Kết quả trả về `yes` hoặc `no`.
</details>

---

## 4. Bài Lab Tiếp Theo

Trong bài lab tiếp theo (**Lab 22**), chúng ta sẽ khám phá bài toán lưu trữ dữ liệu bền vững trong Kubernetes: **Volumes, PersistentVolume (PV), PersistentVolumeClaim (PVC), StorageClass và ứng dụng cơ sở dữ liệu có trạng thái với StatefulSet**!
