# Bước 3: Kiểm thử phân tải và quan sát round-robin

## Lý thuyết

**Least Connections**: request mới đến backend có ít kết nối nhất — tốt hơn Round Robin khi request có thời gian xử lý khác nhau.

**Passive Health Check** (Nginx `max_fails`): tự động đánh dấu backend `down` sau N lần lỗi liên tiếp.

---

## Thực hành

### 3.1 — Quan sát phân phối

```bash
for i in $(seq 1 10); do
  echo "Request $i: $(curl -s http://localhost/server-id)"
done
```

### 3.2 — Đếm tỷ lệ qua 100 request

```bash
declare -A COUNT
for i in $(seq 1 100); do
  SRV=$(curl -s http://localhost/server-id | grep -oP 'app-\d+')
  COUNT[$SRV]=$((${COUNT[$SRV]:-0} + 1))
done

for SRV in "${!COUNT[@]}"; do
  PCT=$(( COUNT[$SRV] ))
  printf "  %-8s: %3d/100 requests\n" "$SRV" "$PCT"
done
echo "(Lý tưởng: ~50% mỗi backend)"
```

### 3.3 — Benchmark baseline

```bash
wrk -t4 -c50 -d15s http://localhost/server-id
```

### 3.4 — Giả lập backend lỗi

```bash
# Làm app-2 fail health check
docker exec app-2 sh -c "echo 'error' > /usr/share/nginx/html/health"

echo "app-2 đang lỗi — 10 request:"
for i in $(seq 1 10); do curl -s http://localhost/server-id; echo; done

# Phục hồi
docker exec app-2 sh -c "echo 'healthy' > /usr/share/nginx/html/health"
echo "✅ app-2 phục hồi"
```

---

## Câu hỏi

1. Tỷ lệ phân phối có bao giờ đạt chính xác 50/50 không? Tại sao?
2. Passive health check (Nginx `max_fails`) và Active health check (AWS ALB) khác nhau thế nào?
3. Nếu app-1 xử lý nhanh gấp đôi app-2, dùng Round Robin hay Least Connections?
