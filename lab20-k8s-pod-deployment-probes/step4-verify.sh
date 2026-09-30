#!/bin/bash

# Kiểm tra Deployment probe-deploy tồn tại
if ! kubectl get deployment probe-deploy > /dev/null 2>&1; then
  echo "Chua tim thay Deployment 'probe-deploy'!"
  exit 1
fi

# Kiểm tra Liveness Probe và Readiness Probe
LIVENESS=$(kubectl get deployment probe-deploy -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.path}' 2>/dev/null)
READINESS=$(kubectl get deployment probe-deploy -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}' 2>/dev/null)

if [ -z "$LIVENESS" ]; then
  echo "Deployment 'probe-deploy' thieu cau hinh livenessProbe!"
  exit 1
fi

if [ -z "$READINESS" ]; then
  echo "Deployment 'probe-deploy' thieu cau hinh readinessProbe!"
  exit 1
fi

# Kiểm tra số lượng bản sao sẵn sàng
SPEC_REP=$(kubectl get deployment probe-deploy -o jsonpath='{.spec.replicas}')
READY_REP=$(kubectl get deployment probe-deploy -o jsonpath='{.status.readyReplicas}')

if [ "$READY_REP" -ne "$SPEC_REP" ]; then
  echo "Cac ban sao cua 'probe-deploy' chua san sang (Ready: $READY_REP/$SPEC_REP). Vui long kiem tra lai!"
  exit 1
fi

# Kiểm tra pod standalone-worker đã được dọn dẹp
if kubectl get pod standalone-worker > /dev/null 2>&1; then
  echo "Pod 'standalone-worker' van con ton tai. Vui long xoa pod nay de hoan tat don dep!"
  exit 1
fi

echo "Xuat sac! Deployment 'probe-deploy' hoat dong hoan hao voi day du Probes va tai nguyen da duoc don dep sach se."
exit 0
