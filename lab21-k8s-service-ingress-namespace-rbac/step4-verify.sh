#!/bin/bash

# 1. Kiểm tra ServiceAccount deploy-admin trong namespace development
if ! kubectl get sa deploy-admin -n development > /dev/null 2>&1; then
  echo "Chua tim thay ServiceAccount 'deploy-admin' trong namespace 'development'!"
  exit 1
fi

# 2. Kiểm tra Role deploy-manager trong namespace development
if ! kubectl get role deploy-manager -n development > /dev/null 2>&1; then
  echo "Chua tim thay Role 'deploy-manager' trong namespace 'development'!"
  exit 1
fi

# 3. Kiểm tra RoleBinding manage-deploy-binding
if ! kubectl get rolebinding manage-deploy-binding -n development > /dev/null 2>&1; then
  echo "Chua tim thay RoleBinding 'manage-deploy-binding' trong namespace 'development'!"
  exit 1
fi

# 4. Kiểm tra quyền create deployments (phải là yes)
CAN_CREATE=$(kubectl auth can-i create deployments --as=system:serviceaccount:development:deploy-admin -n development 2>/dev/null)
if [ "$CAN_CREATE" != "yes" ]; then
  echo "ServiceAccount 'deploy-admin' chua duoc cap quyen create deployments (Ket qua can-i: $CAN_CREATE)!"
  exit 1
fi

# 5. Kiểm tra quyền delete services (phải là no)
CAN_DELETE_SVC=$(kubectl auth can-i delete services --as=system:serviceaccount:development:deploy-admin -n development 2>/dev/null)
if [ "$CAN_DELETE_SVC" != "no" ]; then
  echo "ServiceAccount 'deploy-admin' khong duoc phep co quyen delete services!"
  exit 1
fi

echo "Xuat sac! He thong phan quyen RBAC da duoc thiet lap chuan xac va kiem thu bao mat thanh cong."
exit 0
