#!/bin/bash

REPO="/root/devops-app"
BARE="/srv/git/central-repo.git"

# 1. Kiem tra xem con o trang thai MERGING hay khong
if [ -f "$REPO/.git/MERGE_HEAD" ]; then
    echo "[ERROR] Qua trinh merge chua hoan tat. Hay sua xong cac file, chay 'git add' va 'git commit'."
    exit 1
fi

# 2. Kiem tra xem con sot the danh dau xung dot khong
if grep -rE "<<<<<<<|=======|>>>>>>>" "$REPO/config.yaml" "$REPO/app.py" 2>/dev/null; then
    echo "[ERROR] Van con sot cac ky hieu conflict marker (<<<<<<<, =======, >>>>>>>) trong config.yaml hoac app.py."
    exit 1
fi

# 3. Kiem tra logic dung hoa trong config.yaml
if ! grep -q "payment_gateway" "$REPO/config.yaml" || ! grep -q "timeout" "$REPO/config.yaml"; then
    echo "[ERROR] File config.yaml thieu cau hinh. Can phai co ca 'payment_gateway: stripe' va 'timeout: 30'."
    exit 1
fi

# 4. Kiem tra ham process_payment trong app.py
if ! grep -q "process_payment" "$REPO/app.py"; then
    echo "[ERROR] File app.py chua tich hop ham process_payment tu nhanh feature/payment."
    exit 1
fi

# 5. Kiem tra commit da duoc push len remote central repo chua
if ! git --git-dir="$BARE" show main:config.yaml 2>/dev/null | grep -q "payment_gateway"; then
    echo "[ERROR] Thay doi chua duoc day len remote server. Hay chay: git push origin main"
    exit 1
fi

echo "[SUCCESS] Giai quyet xung dot hoan hao! Ca 2 tinh nang da duoc dung hoa an toan va push thanh cong len Central Server."
exit 0
