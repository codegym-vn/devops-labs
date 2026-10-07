#!/bin/bash

if [ ! -f /root/container-security-lab/dockerfile-misconfig.json ]; then
  echo "Chua xuat bao cao quet cau hinh ra dockerfile-misconfig.json."
  exit 1
fi

if ! grep -q "Misconfigurations" /root/container-security-lab/dockerfile-misconfig.json; then
  echo "Tep dockerfile-misconfig.json khong hop le."
  exit 1
fi

echo "Buoc 2 da hoan thanh thanh cong!"
exit 0
