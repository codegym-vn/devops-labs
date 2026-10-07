#!/bin/bash
set -e

# 1. Kiem tra ung dung dang lang nghe tren cong 3000
if ! curl -s http://localhost:3000/api/health | grep -q '"status":"UP"'; then
  echo "Loi: Ung dung web muc tieu chua khoi chay tren cong 3000!"
  exit 1
fi

echo "Ung dung web muc tieu dang hoat dong san sang cho kiem thu DAST!"
exit 0
