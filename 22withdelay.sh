#!/usr/bin/env bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "===== WAITING FOR CLOUD-INIT ====="

# Wait for cloud-init to finish
if command -v cloud-init >/dev/null 2>&1; then
  sudo cloud-init status --wait || true
fi

echo "===== WAITING FOR APT LOCKS ====="

# Wait for apt locks
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
  echo "Waiting for dpkg lock..."
  sleep 5
done

while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
  echo "Waiting for apt lists lock..."
  sleep 5
done

while sudo fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do
  echo "Waiting for apt archives lock..."
  sleep 5
done

echo "===== APT UPDATE ====="

# Retry apt update
for i in {1..5}; do
  sudo apt-get update \
    -o Acquire::Retries=5 \
    -o Acquire::http::Timeout=60 && break

  echo "apt update failed... retrying"
  sleep 15
done

echo "===== INSTALL CORE PACKAGES ====="

# Retry install
for i in {1..5}; do
  sudo apt-get install -y \
    unzip \
    zip \
    gnupg \
    gpg \
    curl \
    wget \
    lsb-release \
    software-properties-common \
    jq \
    python3 \
    python3-pip \
    python3-setuptools \
    --fix-missing && break

  echo "apt install failed... retrying"
  sleep 15
done

echo "===== INSTALL PYTHON 3.12 ====="

sudo add-apt-repository -y ppa:deadsnakes/ppa

sudo apt-get update

for i in {1..5}; do
  sudo apt-get install -y \
    python3.12 \
    python3.12-venv \
    python3.12-dev \
    --fix-missing && break

  echo "python3.12 install failed... retrying"
  sleep 15
done

echo "===== VERIFY PYTHONS ====="

/usr/bin/python3 --version
/usr/bin/python3.12 --version

echo "===== INSTALL TERRAFORM ====="

wget -O- https://apt.releases.hashicorp.com/gpg \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update
sudo apt-get install -y terraform

echo "===== INSTALL AZURE CLI ====="

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

echo "===== PREPARE AGENT DIR ====="

sudo mkdir -p /agent
sudo chmod 777 /agent
sudo rm -f /agent/.agent.lock

echo "===== FINAL VERSION CHECK ====="

echo "System Python:"
/usr/bin/python3 --version

echo "Pipeline Python:"
/usr/bin/python3.12 --version

terraform version | head -1

az version --query '"azure-cli"' -o tsv

echo "===== SUCCESS ====="
