#!/bin/bash

# Kiem tra file parsers.conf
if [ ! -f /root/centralized-logging-lab/parsers.conf ]; then
  echo "Chua tim thay tep /root/centralized-logging-lab/parsers.conf."
  exit 1
fi

if ! grep -q "nginx_parser" /root/centralized-logging-lab/parsers.conf; then
  echo "Tep parsers.conf chua dinh nghia bo giai ma nginx_parser."
  exit 1
fi

# Kiem tra file fluent-bit.conf
if [ ! -f /root/centralized-logging-lab/fluent-bit.conf ]; then
  echo "Chua tim thay tep /root/centralized-logging-lab/fluent-bit.conf."
  exit 1
fi

if ! grep -q "record_modifier" /root/centralized-logging-lab/fluent-bit.conf; then
  echo "Tep fluent-bit.conf chua ap dung Filter record_modifier."
  exit 1
fi

echo "Buoc 2 da hoan thanh xuat sac!"
exit 0
