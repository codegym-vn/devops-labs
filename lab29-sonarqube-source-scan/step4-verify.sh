#!/bin/bash

SCRIPT=/root/sonarqube-lab/check-quality-gate.sh

if [ ! -x "$SCRIPT" ]; then
  echo "Tep $SCRIPT chua ton tai hoac chua duoc chmod +x."
  exit 1
fi

OUTPUT=$("$SCRIPT" 2>&1)
if ! echo "$OUTPUT" | grep -q "GATE PASSED"; then
  echo "Script khong tra ve GATE PASSED. Chi tiet: $OUTPUT"
  exit 1
fi

echo "Buoc 4 hoan thanh"
exit 0
