# Bước 1: Cấp Phát Bộ Lưu Trữ Động Với StorageClass Và PersistentVolumeClaim

Mặc định trong Kubernetes, hệ thống tệp tin (filesystem) của vùng chứa có tính chất tạm thời (ephemeral): khi một container gặp sự cố và khởi động lại, mọi dữ liệu ghi trên ổ đĩa nội bộ của nó sẽ bị xóa sạch. Để lưu trữ dữ liệu bền vững (Persistent Storage), Kubernetes cung cấp kiến trúc trừu tượng hóa ba tầng: **StorageClass**, **PersistentVolume (PV)** và **PersistentVolumeClaim (PVC)**.

---

## 1. Cơ Chế Cấp Phát Động (Dynamic Provisioning)

```
┌─────────────────────────────────────────────────────────────┐
│ 1. StorageClass (Nhà máy tự động hóa):                      │
│    Định nghĩa loại ổ đĩa hạ tầng (AWS EBS, NFS, Local-Path) │
└──────────────────────────────┬──────────────────────────────┘
                               │ Tự động lắng nghe và cấp phát
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. PersistentVolumeClaim (Phiếu yêu cầu của nhà phát triển):│
│    - Cần: 100Mi dung lượng                                  │
│    - Chế độ: ReadWriteOnce (RWO)                            │
└──────────────────────────────┬──────────────────────────────┘
                               │ Liên kết (Bound)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. PersistentVolume (Ổ đĩa thực tế được tự động sinh ra):   │
│    Tồn tại độc lập với vòng đời của Pod                     │
└─────────────────────────────────────────────────────────────┘
```

* **Cấp phát tĩnh (Static Provisioning):** Quản trị viên phải tạo sẵn từng PV thủ công. Khi người dùng tạo PVC, hệ thống tìm PV có dung lượng khớp để gán ghép. Cách làm này tốn nhiều công sức và không thể mở rộng.
* **Cấp phát động (Dynamic Provisioning):** Khi người dùng gửi PVC yêu cầu ổ đĩa, `StorageClass` sẽ tự động tạo ra một PV tương ứng ngay tức khắc mà không cần sự can thiệp thủ công của con người.
* **Chế độ truy cập phổ biến (Access Modes):**
  * `ReadWriteOnce (RWO)`: Ổ đĩa chỉ có thể được gắn kết đọc/ghi bởi duy nhất 1 Node tại một thời điểm (thường dùng cho các loại ổ đĩa khối như AWS EBS, GCP Persistent Disk, Local Disk).
  * `ReadWriteMany (RWX)`: Ổ đĩa có thể được gắn kết đọc/ghi đồng thời bởi nhiều Node (thường dùng cho hệ thống tệp tin mạng chia sẻ như NFS, CephFS).

---

## 2. Các Bước Thực Hành Hướng Dẫn

### 2.1 — Khám phá StorageClass mặc định trên cụm

Kiểm tra danh sách các lớp lưu trữ đang sẵn sàng:

```bash
kubectl get storageclass
```{{exec}}

Bạn sẽ thấy StorageClass `local-path` có chú thích `(default)`, nghĩa là mọi PVC tạo ra không chỉ định rõ lớp lưu trữ sẽ tự động được `local-path` tiếp nhận và cấp phát đĩa động.

---

### 2.2 — Khởi tạo PersistentVolumeClaim yêu cầu cấp phát ổ đĩa

Tạo tệp khai báo `demo-pvc.yaml` yêu cầu `100Mi` dung lượng:

```bash
cat << 'EOF' > /root/k8s-advanced/demo-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: demo-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
EOF
```{{exec}}

Áp dụng cấu hình:

```bash
kubectl apply -f /root/k8s-advanced/demo-pvc.yaml
```{{exec}}

Kiểm tra trạng thái của PVC và PV tự động sinh ra:

```bash
kubectl get pvc demo-pvc
kubectl get pv
```{{exec}}

Cột **STATUS** hiển thị chữ `Bound`, chứng minh StorageClass đã tự động khởi tạo thành công một đĩa PersistentVolume và ghép nối hoàn tất với PVC!

---

### 2.3 — Gắn kết ổ đĩa bền vững vào Pod và kiểm chứng an toàn dữ liệu

Tạo Pod `writer-pod` gắn kết ổ đĩa vào thư mục `/data` và ghi một tệp tin:

```bash
cat << 'EOF' > /root/k8s-advanced/writer-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: writer-pod
spec:
  containers:
  - name: alpine
    image: alpine:latest
    command: ["sh", "-c", "echo 'Du lieu ghi vao luc: '$(date) > /data/persistent-log.txt && sleep 3600"]
    volumeMounts:
    - name: data-volume
      mountPath: /data
  volumes:
  - name: data-volume
    persistentVolumeClaim:
      claimName: demo-pvc
EOF
```{{exec}}

Khởi chạy Pod và đợi dữ liệu được ghi:

```bash
kubectl apply -f /root/k8s-advanced/writer-pod.yaml
sleep 3
kubectl exec writer-pod -- cat /data/persistent-log.txt
```{{exec}}

Bây giờ, hãy thử **xóa hoàn toàn Pod này**:

```bash
kubectl delete pod writer-pod
```{{exec}}

Khởi tạo một Pod mới tên là `reader-pod` cùng gắn kết lại `demo-pvc`:

```bash
cat << 'EOF' > /root/k8s-advanced/reader-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: reader-pod
spec:
  containers:
  - name: alpine
    image: alpine:latest
    command: ["sh", "-c", "cat /data/persistent-log.txt && sleep 3600"]
    volumeMounts:
    - name: data-volume
      mountPath: /data
  volumes:
  - name: data-volume
    persistentVolumeClaim:
      claimName: demo-pvc
EOF
```{{exec}}

Khởi chạy `reader-pod` và kiểm tra nội dung:

```bash
kubectl apply -f /root/k8s-advanced/reader-pod.yaml
sleep 3
kubectl logs reader-pod
```{{exec}}

Dữ liệu cũ vẫn được bảo toàn nguyên vẹn 100%!

---

## 3. Bài Tập Thử Thách

> [!TIP] Hãy hoàn thành các thao tác hướng dẫn ở trên trước khi thực hiện thử thách tự lập này.

Ứng dụng nhật ký giao dịch cần một vùng lưu trữ riêng biệt được cấp phát động với dung lượng lớn hơn.

**Yêu cầu:**
1. Khởi tạo một đối tượng PersistentVolumeClaim có tên là `app-data-pvc` trong namespace mặc định (`default`).
2. Yêu cầu dung lượng lưu trữ chính xác là `500Mi`.
3. Sử dụng chế độ truy cập `ReadWriteOnce`.
4. Xác nhận rằng PVC `app-data-pvc` đã được tiếp nhận và đạt trạng thái `Bound` (đã được liên kết với một PersistentVolume thực tế).

**Gợi ý:**
- Khai báo chuẩn tài nguyên `apiVersion: v1` với `kind: PersistentVolumeClaim`.
- Trong khối `spec`, thiết lập `accessModes` là `[ReadWriteOnce]` và định nghĩa dung lượng trong `resources.requests.storage: 500Mi`.
- Sử dụng lệnh `kubectl get pvc app-data-pvc` để kiểm tra cột STATUS chuyển sang `Bound`.

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
