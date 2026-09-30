#!/bin/bash

# Kiểm tra Secret api-credentials tồn tại
if ! kubectl get secret api-credentials > /dev/null 2>&1; then
  echo "Chua tim thay Secret 'api-credentials'. Vui long khoi tao theo dung ten yeu cau!"
  exit 1
fi

# Kiểm tra trường API_KEY trong data
ENCODED_VAL=$(kubectl get secret api-credentials -o jsonpath='{.data.API_KEY}' 2>/dev/null)
if [ -z "$ENCODED_VAL" ]; then
  echo "Secret 'api-credentials' khong chua khoa 'API_KEY'!"
  exit 1
fi

# Giải mã Base64 và so sánh giá trị
DECODED_VAL=$(echo "$ENCODED_VAL" | base64 -d)
if [ "$DECODED_VAL" != "SuperSecretKey99" ]; then
  echo "Gia tri cua API_KEY khong dung voi yeu cau (SuperSecretKey99)!"
  exit 1
fi

echo "Chuc mung! Secret 'api-credentials' da duoc khoi tao voi khoa va gia tri bi mat hoan toan chinh xac."
exit 0
