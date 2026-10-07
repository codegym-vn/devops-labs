#!/bin/bash

if ! curl -s http://localhost:3000/api/health | grep -q '"status":"UP"'; then
  echo "Ung dung chua chay tren cong 3000. Hay chay npm install va nohup node server.js."
  exit 1
fi

echo "Buoc 1 hoan thanh"
exit 0
