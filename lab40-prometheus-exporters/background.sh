#!/bin/bash

# Luon danh dau hoan tat khi thoat script de tranh treo foreground
trap 'touch /tmp/background-finished' EXIT

mkdir -p /root/prometheus-lab
cd /root/prometheus-lab

# 1. Pre-pull san cac Docker Image can thiet trong background
docker pull prom/node-exporter:v1.8.0 > /dev/null 2>&1 &
docker pull redis:7-alpine > /dev/null 2>&1 &
docker pull oliver006/redis_exporter:v1.58.0 > /dev/null 2>&1 &
docker pull prom/prometheus:v2.51.0 > /dev/null 2>&1 &

# 2. Xoa sach container cu neu ton tai
docker rm -f node-exporter redis redis-exporter prometheus > /dev/null 2>&1 || true

# 3. Danh dau hoan tat
touch /tmp/background-finished
