#!/bin/bash

# Dam bao git da san sang (Killercoda Ubuntu da cai san git)
if ! command -v git &> /dev/null; then
    apt-get update -y > /dev/null 2>&1
    apt-get install -y git > /dev/null 2>&1
fi

# Cau hinh Git mac dinh
git config --global user.name "DevOps Engineer"
git config --global user.email "devops@lab.local"
git config --global init.defaultBranch main

# Khoi tao Central Bare Repository tai /srv/git/central-repo.git
mkdir -p /srv/git/central-repo.git
git init --bare /srv/git/central-repo.git > /dev/null 2>&1

# Khoi tao Working Repository tai /root/devops-app
mkdir -p /root/devops-app
cd /root/devops-app
git init > /dev/null 2>&1
git remote add origin /srv/git/central-repo.git

# Commit 1: Khoi tao du an tren main
echo "# DevOps Microservices Platform" > README.md
cat << 'EOF' > config.yaml
app:
  name: devops-platform
  port: 8000
  debug: false
database:
  host: localhost
  port: 5432
EOF

cat << 'EOF' > app.py
def get_config():
    return {"service": "running"}

def process_data(data):
    print("Processing: " + str(data))
    return True

if __name__ == "__main__":
    print("Application started.")
EOF

git add README.md config.yaml app.py
git commit -m "feat: initial project setup" > /dev/null 2>&1
git push -u origin main > /dev/null 2>&1

# Tao nhanh feature/payment (se xung dot voi main o Buoc 2)
git checkout -b feature/payment > /dev/null 2>&1
cat << 'EOF' > config.yaml
app:
  name: devops-platform
  port: 9000
  debug: false
  payment_gateway: stripe
database:
  host: localhost
  port: 5432
EOF

cat << 'EOF' > app.py
def get_config():
    return {"service": "running", "payment": "enabled"}

def process_data(data):
    print("Processing: " + str(data))
    return True

def process_payment(amount):
    print("Charging: " + str(amount))
    return True

if __name__ == "__main__":
    print("Application started.")
EOF

git add config.yaml app.py
git commit -m "feat(payment): integrate stripe payment gateway and switch port to 9000" > /dev/null 2>&1
git push -u origin feature/payment > /dev/null 2>&1

# Quay lai main va commit thay doi gay xung dot (dong nghiep sua cung file)
git checkout main > /dev/null 2>&1
cat << 'EOF' > config.yaml
app:
  name: devops-platform
  port: 8080
  debug: true
database:
  host: localhost
  port: 5432
  timeout: 30
EOF

cat << 'EOF' > app.py
def get_config():
    return {"service": "running", "env": "production"}

def process_data(data):
    print("Validating and processing: " + str(data))
    return True

if __name__ == "__main__":
    print("Application started.")
EOF

git add config.yaml app.py
git commit -m "chore(main): update server port to 8080 and add database timeout" > /dev/null 2>&1
git push origin main > /dev/null 2>&1

# Tao nhanh feature/notification (phuc vu Buoc 3 - Rebase)
git checkout -b feature/notification HEAD~1 > /dev/null 2>&1
cat << 'EOF' >> app.py

def send_notification(msg):
    print("Sending notification: " + str(msg))
    return True
EOF
git add app.py
git commit -m "feat(notify): add basic notification function" > /dev/null 2>&1
git push -u origin feature/notification > /dev/null 2>&1

# Chuyen ve lai nhanh main trong thu muc devops-app
git checkout main > /dev/null 2>&1

# Danh dau san sang tuc thi
touch /tmp/.lab_ready
