#!/bin/bash

# Cap nhat va cai dat git, tree
apt-get update -y > /dev/null 2>&1
apt-get install -y git tree > /dev/null 2>&1

# Cau hinh Git mac dinh
git config --global user.name "DevOps Engineer"
git config --global user.email "devops@lab.local"
git config --global init.defaultBranch main

# Khoi tao repository mau tai /root/devops-project
mkdir -p /root/devops-project
cd /root/devops-project
git init > /dev/null 2>&1

# Commit 1: Khoi tao du an
echo "# DevOps Microservices Project" > README.md
cat << 'EOF' > app.py
def main():
    print("Hello from DevOps API Service")

if __name__ == "__main__":
    main()
EOF
git add README.md app.py
git commit -m "feat: initial commit with app structure" > /dev/null 2>&1

# Commit 2: Them scripts va file bi mat cho thu thach Buoc 1
mkdir -p scripts
cat << 'EOF' > scripts/deploy.sh
#!/bin/bash
echo "Deploying application to production..."
EOF
chmod +x scripts/deploy.sh
echo "API_TOKEN_XYZ_98765_RECOVERED" > scripts/secret.txt
git add scripts/
git commit -m "chore: add deploy scripts and secret token" > /dev/null 2>&1

# Tao branch feature-payment, commit roi xoa di de phuc vu Buoc 2 (Reflog)
git checkout -b feature-payment > /dev/null 2>&1
cat << 'EOF' > payment.py
def process_payment(amount):
    print("Processing payment of amount: " + str(amount))
    return True
EOF
git add payment.py
git commit -m "feat(payment): implement payment processing module" > /dev/null 2>&1

# Quay lai main va xoa branch feature-payment de lam du lieu mat
git checkout main > /dev/null 2>&1
git branch -D feature-payment > /dev/null 2>&1

# Danh dau moi truong da san sang
touch /tmp/.lab_ready
