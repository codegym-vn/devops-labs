#!/bin/bash
set -e

# 1. Cai dat tfsec binary
if ! command -v tfsec > /dev/null 2>&1; then
  curl -fsSL -o /usr/local/bin/tfsec https://github.com/aquasecurity/tfsec/releases/download/v1.28.13/tfsec-linux-amd64 2>/dev/null || \
  curl -fsSL https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
  chmod +x /usr/local/bin/tfsec 2>/dev/null || true
fi

# 2. Cai dat Checkov thong qua Docker container wrapper
docker pull bridgecrew/checkov:latest > /dev/null 2>&1 &

cat << 'EOF' > /usr/local/bin/checkov
#!/bin/bash
docker run --rm -t -v "$(pwd):/work" -w /work bridgecrew/checkov:latest "$@"
EOF
chmod +x /usr/local/bin/checkov

# 3. Khoi tao thu muc du an Terraform mau chua loi
mkdir -p /root/iac-security-lab
cd /root/iac-security-lab

cat << 'EOF' > provider.tf
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "ap-southeast-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
}
EOF

cat << 'EOF' > insecure_resources.tf
# 1. S3 Bucket chua cac cau hinh thieu bao mat
resource "aws_s3_bucket" "financial_data" {
  bucket = "company-financial-records-2026"
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.financial_data.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 2. Security Group mo port 22 SSH nguy hiem
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-ssh-sg"
  description = "Security group for bastion host"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
EOF

# Khoi tao git repo de phuc vu kiem thu
git config --global user.name "DevOps Learner"
git config --global user.email "learner@devops.lab"
git config --global init.defaultBranch main
git init -q
git add .
git commit -q -m "feat: khoi tao ma nguon ha tang terraform"

wait
touch /tmp/background-finished
