# Bước 3: Quan sát phân phối và kiểm thử

## Lý thuyết

**Round Robin vs Least Connections**:

```
Round Robin:           Least Connections:
Request 1 → app-1     Request 1 → app-1 (0 conn)
Request 2 → app-2     Request 2 → app-2 (0 conn)
Request 3 → app-1     Request 3 → app-1 (app-1 trả lời nhanh hơn, 0 conn)
Request 4 → app-2     Request 4 → app-1 (app-2 vẫn đang xử lý, 1 conn)
```

Least Connections tốt hơn khi request có thời gian xử lý khác nhau.

---

## Thực hành

### 3.1 — Đếm phân phối qua 100 request

```bash
declare -A COUNT
for i in $(seq 1 100); do
  SRV=$(curl -s http://localhost/server-id | tr -d '\n')
  COUNT[$SRV]=$((${COUNT[$SRV]:-0} + 1))
done

echo "=== Phân phối 100 request ==="
for SRV in "${!COUNT[@]}"; do
  N=${COUNT[$SRV]}
  BAR=$(printf '█%.0s' $(seq 1 $((N / 2))))
  printf "  %-8s: %3d/100 %s\n" "$SRV" "$N" "$BAR"
done
echo "(Least Conn → ~50% mỗi backend khi tải đều)"
```

### 3.2 — Benchmark baseline (2 backends)

```bash
# Cài wrk nếu chưa có
apt-get install -y wrk > /dev/null 2>&1 || \
  (apt-get install -y build-essential libssl-dev git > /dev/null 2>&1 && \
   git clone -q https://github.com/wg/wrk /tmp/wrk && \
   make -C /tmp/wrk -s && cp /tmp/wrk/wrk /usr/local/bin/)

echo "=== Benchmark: 2 backends ==="
wrk -t2 -c20 -d15s http://localhost/server-id | tee /tmp/bench-2.txt
grep "Requests/sec" /tmp/bench-2.txt
```

### 3.3 — Giả lập backend lỗi (instance down)

```bash
echo "=== Mô phỏng app-2 down ==="
docker stop app-2
sleep 3

echo "10 request khi app-2 down:"
for i in $(seq 1 10); do
  curl -s http://localhost/server-id; echo ""
done
# Tất cả phải đến app-1

docker start app-2
sleep 2
docker exec app-2 sh -c "echo 'healthy' > /usr/share/nginx/html/health"
echo "✅ app-2 phục hồi"
```

---

## Câu hỏi

1. Tỷ lệ phân phối có bao giờ chính xác 50/50 không? Tại sao?
2. Passive health check (`max_fails`) và Active health check (ALB polling) khác thế nào?
3. Nếu app-1 nhanh gấp đôi app-2, thuật toán nào phù hợp hơn?
