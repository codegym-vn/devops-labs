#!/bin/bash
echo "Dang khoi tao moi truong OpenTelemetry va Jaeger, vui long cho trong giay lat..."
WAIT_SEC=0
while [ ! -f /tmp/background-finished ] && [ $WAIT_SEC -lt 30 ]; do
  sleep 1
  WAIT_SEC=$((WAIT_SEC + 1))
done
clear
echo "=================================================================="
echo "  Chao mung den voi Lab 38: Instrument va Trace mot Request       "
echo "  Moi truong OpenTelemetry SDK & Jaeger All-in-One da san sang!  "
echo "=================================================================="
cd /root/tracing-lab
