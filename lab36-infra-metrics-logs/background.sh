#!/bin/bash
# Khoi tao moi truong lab thu thap metrics va logs ha tang

mkdir -p /root/infra-monitoring-lab
mkdir -p /var/log/infrastructure

# 1. Tao file log ban dau cua ha tang
cat << 'EOF' > /var/log/infrastructure/system.log
2026-10-13T08:00:01Z host=srv-prod-01 component=systemd[1]: Starting Daily apt download activities...
2026-10-13T08:00:05Z host=srv-prod-01 component=systemd[1]: Finished Daily apt download activities.
2026-10-13T08:05:12Z host=srv-prod-01 component=sshd[1024]: Server listening on 0.0.0.0 port 22.
2026-10-13T08:10:20Z host=srv-prod-01 component=kernel: [    0.000000] Linux version 6.5.0-generic (buildd@lcy02-amd64)
2026-10-13T08:15:33Z host=srv-prod-01 component=dockerd[1520]: API listen on /var/run/docker.sock
EOF

# 2. Pre-pull san cac docker image can thiet de tiet kiem thoi gian
docker pull prom/node-exporter:v1.8.0 > /dev/null 2>&1 &
docker pull prom/prometheus:latest > /dev/null 2>&1 &
docker pull grafana/loki:2.9.2 > /dev/null 2>&1 &
docker pull grafana/promtail:2.9.2 > /dev/null 2>&1 &

touch /tmp/background-finished
