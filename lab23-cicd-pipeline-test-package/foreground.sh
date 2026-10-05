#!/bin/bash
clear
echo "================================================================"
echo " 🚀 DevOps Labs: Pipeline CI/CD - Kiem Thu & Dong Goi Ung Dung"
echo "================================================================"
echo ""

STATUS_FILE="/tmp/lab-status.log"
spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
i=0

while [ ! -f /tmp/.lab_ready ]; do
  if [ -f "$STATUS_FILE" ]; then
    STATUS=$(cat "$STATUS_FILE")
  else
    STATUS="Dang chuan bi moi truong CI/CD..."
  fi
  idx=$((i % ${#spinner[@]}))
  printf "\r\033[K %s %s" "${spinner[$idx]}" "$STATUS"
  sleep 0.5
  i=$((i + 1))
done

printf "\r\033[K ✅ Moi truong CI/CD da san sang!\n\n"
echo "----------------------------------------------------------------"
echo "💡 Thong tin moi truong:"
echo "   - Repo ung dung   : /root/cicd-app (nhanh main, feature/discount)"
echo "   - CI runner       : act (chay GitHub Actions cuc bo), cau hinh ~/.actrc"
echo "   - Docker Registry : localhost:5000"
echo "   - Thu muc log CI  : /root/ci-logs"
echo "   - Artifact server : /tmp/artifacts"
echo "----------------------------------------------------------------"
echo ""
echo "🔧 Phien ban cong cu:"
echo "   $(go version 2>/dev/null)"
echo "   act $(act --version 2>/dev/null | awk '{print $NF}')"
echo ""

cd /root/cicd-app 2>/dev/null || true
