#!/bin/bash

# Kiem tra file script ton tai
if [ ! -f /root/monitor.sh ]; then
    echo "[ERROR] File /root/monitor.sh khong ton tai."
    exit 1
fi

# Kiem tra trong script co goi curl toi webhook hay khong
if ! grep -qE "curl.*(9090|WEBHOOK_URL|webhook)" /root/monitor.sh 2>/dev/null; then
    echo "[ERROR] Chua tim thay lenh curl gui du lieu toi webhook trong /root/monitor.sh. Hay them ham gui webhook."
    exit 1
fi

# Kiem tra file log canh bao ton tai va co du lieu
if [ ! -s /var/log/alerts.log ]; then
    echo "[ERROR] File /var/log/alerts.log rong hoac chua ton tai. Hay chay script /root/monitor.sh de gui thu mot canh bao toi webhook."
    exit 1
fi

# Kiem tra noi dung trong alerts.log co chua metric va severity
if grep -qiE "metric|severity" /var/log/alerts.log; then
    LAST_ALERT=$(tail -n 1 /var/log/alerts.log)
    echo "[SUCCESS] Canh bao Webhook da duoc gui va ghi nhan thanh cong vao /var/log/alerts.log!"
    echo "Ban ghi moi nhat: $LAST_ALERT"
    exit 0
else
    echo "[ERROR] File /var/log/alerts.log chua chua payload canh bao hop le (thieu metric hoac severity)."
    exit 1
fi
