#!/bin/bash
PLAN=/root/dast-target-app/remediation-plan.txt

if [ ! -s "$PLAN" ]; then
  echo "Chua co tep remediation-plan.txt."
  exit 1
fi

if [ "$(wc -l < "$PLAN")" -lt 2 ]; then
  echo "remediation-plan.txt chua du danh sach canh bao."
  exit 1
fi

echo "Buoc 3 hoan thanh"
exit 0
