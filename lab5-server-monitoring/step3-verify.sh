#!/bin/bash

# 1. Kiem tra script tai /usr/local/bin/monitor.sh
if [ ! -x /usr/local/bin/monitor.sh ]; then
    echo "[ERROR] Script /usr/local/bin/monitor.sh khong ton tai hoac chua co quyen thuc thi. Hay copy tu /root/monitor.sh va chay chmod +x."
    exit 1
fi

# 2. Kiem tra crontab da duoc cau hinh chua
if ! crontab -l 2>/dev/null | grep -qE "monitor\.sh"; then
    echo "[ERROR] Chua tim thay tac vu monitor.sh trong crontab cua root. Hay them dong lap lich: * * * * * /usr/local/bin/monitor.sh >> /var/log/monitor.log 2>&1"
    exit 1
fi

# 3. Kiem tra xem da co canh bao CRITICAL trong alerts.log chua
if ! grep -qi "CRITICAL" /var/log/alerts.log 2>/dev/null; then
    echo "[ERROR] Chua tim thay canh bao CRITICAL trong /var/log/alerts.log. Hay chay stress-ng de day tai CPU len cao va chay script de kich hoat canh bao CRITICAL."
    exit 1
fi

LAST_CRIT=$(grep -i "CRITICAL" /var/log/alerts.log | tail -n 1)
echo "[SUCCESS] He thong giam sat tu dong hoat dong hoan hao!"
echo "Crontab da duoc lap lich dung va canh bao CRITICAL da duoc ghi nhan:"
echo "$LAST_CRIT"
exit 0
