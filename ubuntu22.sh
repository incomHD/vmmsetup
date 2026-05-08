#!/usr/bin/env bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

# ─────────────────────────────────────────────
# 1. DO NOT BREAK APT (IMPORTANT FIX)
# ─────────────────────────────────────────────
sudo apt-get update -o Acquire::Retries=5

# ─────────────────────────────────────────────
# 2. Core VMSS tools (SAFE)
# ─────────────────────────────────────────────
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
  python3-venv \
  python3-pip \
  python3-setuptools

# ─────────────────────────────────────────────
# 3. Add Python 3.14 (SAFE WAY - NO COMPILATION)
# ─────────────────────────────────────────────
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt-get update -o Acquire::Retries=5

sudo apt-get install -y \
  python3.14 \
  python3.14-venv \
  python3.14-dev

# Verify versions
/usr/bin/python3 --version
/usr/bin/python3.14 --version

# ─────────────────────────────────────────────
# 4. Terraform
# ─────────────────────────────────────────────
wget -O- https://apt.releases.hashicorp.com/gpg \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update
sudo apt-get install -y terraform

# ─────────────────────────────────────────────
# 5. Azure CLI
# ─────────────────────────────────────────────
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# ─────────────────────────────────────────────
# 6. pipx + audit using Python 3.14 (isolated)
# ─────────────────────────────────────────────
/usr/bin/python3.14 -m pip install --upgrade pip pipx
/usr/bin/python3.14 -m pipx ensurepath

export PATH=$PATH:/root/.local/bin

pipx install pip-audit || true

# ─────────────────────────────────────────────
# 7. Agent safe directory
# ─────────────────────────────────────────────
sudo mkdir -p /agent
sudo chmod 777 /agent
sudo rm -f /agent/.agent.lock

# ─────────────────────────────────────────────
# 8. Final verification
# ─────────────────────────────────────────────
echo ""
echo "===== FINAL VERSION CHECK ====="
echo "System Python (VMSS/Agent): $(/usr/bin/python3 --version)"
echo "Python 3.14 (Pipeline runtime): $(/usr/bin/python3.14 --version)"
echo "Terraform: $(terraform version | head -1)"
echo "Azure CLI: $(az version --query '\"azure-cli\"' -o tsv)"
echo ""
echo "===== SUCCESS ====="
