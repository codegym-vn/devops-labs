#!/bin/bash
echo "Dang khoi tao moi truong OpenTelemetry va Jaeger, vui long cho trong giay lat..."
while [ ! -f /tmp/background-finished ]; do
  sleep 1
done
clear
echo "=================================================================="
echo "  Chao mung den voi Lab 38: Instrument va Trace mot Request       "
echo "  Moi truong OpenTelemetry SDK & Jaeger All-in-One da san sang!  "
echo "=================================================================="
cd /root/tracing-lab
