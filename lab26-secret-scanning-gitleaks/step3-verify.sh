#!/bin/bash

HOOK_FILE="/root/secret-leak-lab/.git/hooks/pre-commit"

# Kiểm tra file hook tồn tại
if [ ! -f "$HOOK_FILE" ]; then
  echo "Chua tim thay tep hook '$HOOK_FILE'. Hay tao tep theo huong dan!"
  exit 1
fi

# Kiểm tra quyền thực thi của hook
if [ ! -x "$HOOK_FILE" ]; then
  echo "Tep hook '$HOOK_FILE' chua duoc cap quyen thuc thi (chmod +x)!"
  exit 1
fi

# Kiểm tra nội dung hook có lệnh gitleaks protect
if ! grep -q "gitleaks protect --staged" "$HOOK_FILE"; then
  echo "Tep hook chua chua lenh 'gitleaks protect --staged'. Vui long kiem tra lai!"
  exit 1
fi

echo "Chuc mung! Git Pre-commit Hook da duoc thiet lap va hoat dong hoan hao."
exit 0
