#!/bin/bash

REPO="/root/devops-app"
BARE="/srv/git/central-repo.git"

# 1. Kiem tra xem co dang bi ket trong tien trinh rebase khong
if [ -d "$REPO/.git/rebase-merge" ] || [ -d "$REPO/.git/rebase-apply" ]; then
    echo "[ERROR] Tien trinh rebase chua hoan tat. Hay sua xong conflict trong app.py, chay 'git add app.py' va 'git rebase --continue'."
    exit 1
fi

# 2. Kiem tra xem con sot the conflict marker khong
if grep -rE "<<<<<<<|=======|>>>>>>>" "$REPO/app.py" 2>/dev/null; then
    echo "[ERROR] Van con sot the conflict marker trong app.py."
    exit 1
fi

# 3. Kiem tra ham send_notification co trong app.py tren main khong
if ! grep -q "send_notification" "$REPO/app.py"; then
    echo "[ERROR] Ham send_notification chua co trong app.py tren nhanh main."
    exit 1
fi

# 4. Kiem tra commit squash tren main co message lien quan den notify khong
LAST_MSG=$(git -C "$REPO" log -1 --pretty=%s)
if ! echo "$LAST_MSG" | grep -qiE "notify|notification"; then
    echo "[ERROR] Commit gan nhat tren main chua dung message squash yeu cau."
    echo "Message hien tai: $LAST_MSG"
    echo "Message mong doi: feat(notify): add notification system to microservice"
    exit 1
fi

# 5. Kiem tra code da duoc push len remote server chua
if ! git --git-dir="$BARE" show main:app.py 2>/dev/null | grep -q "send_notification"; then
    echo "[ERROR] Thay doi chua duoc day len remote server. Hay chay: git push origin main"
    exit 1
fi

echo "[SUCCESS] Tuyet voi! Ban da thuc hien thanh cong Rebase giai quyet xung dot va Squash & Merge tinh nang vao main chuan DevOps."
exit 0
