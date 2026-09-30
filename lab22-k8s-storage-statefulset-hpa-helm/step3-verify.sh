#!/bin/bash

# 1. Kiểm tra HPA web-hpa tồn tại
if ! kubectl get hpa web-hpa > /dev/null 2>&1; then
  echo "Chua tim thay HorizontalPodAutoscaler 'web-hpa' trong default namespace!"
  exit 1
fi

# 2. Kiểm tra target deployment
TARGET=$(kubectl get hpa web-hpa -o jsonpath='{.spec.scaleTargetRef.name}')
if [ "$TARGET" != "php-apache" ]; then
  echo "Doi tuong co gian muc tieu phai la 'php-apache' (Hien tai: $TARGET)!"
  exit 1
fi

# 3. Kiểm tra minReplicas và maxReplicas
MIN_REP=$(kubectl get hpa web-hpa -o jsonpath='{.spec.minReplicas}')
MAX_REP=$(kubectl get hpa web-hpa -o jsonpath='{.spec.maxReplicas}')

if [ "$MIN_REP" -ne 2 ] || [ "$MAX_REP" -ne 6 ]; then
  echo "Nguong ban sao chua dung: minReplicas=$MIN_REP (yeu cau: 2), maxReplicas=$MAX_REP (yeu cau: 6)!"
  exit 1
fi

# 4. Kiểm tra target CPU utilization (60%)
TARGET_CPU=$(kubectl get hpa web-hpa -o jsonpath='{.spec.metrics[?(@.type=="Resource")].resource.target.averageUtilization}' 2>/dev/null)
if [ -z "$TARGET_CPU" ]; then
  TARGET_CPU=$(kubectl get hpa web-hpa -o jsonpath='{.spec.targetCPUUtilizationPercentage}' 2>/dev/null)
fi

if [ "$TARGET_CPU" -ne 60 ]; then
  echo "Nguong CPU muc tieu chua dung: $TARGET_CPU% (yeu cau: 60%)!"
  exit 1
fi

echo "Chuc mung! HorizontalPodAutoscaler 'web-hpa' da duoc thiet lap chinh xac voi day du nguong tai."
exit 0
