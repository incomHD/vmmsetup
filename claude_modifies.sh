#!/usr/bin/env bash
set -euxo pipefail
 
export DEBIAN_FRONTEND=noninteractive
 
# ─── Cleanup & Update ─────────────────────────────────────────────────────────
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
sudo apt-get update --allow-releaseinfo-change -o Acquire::Retries=5
 
# ─── Core Tools ───────────────────────────────────────────────────────────────
sudo apt-get install -y \
  unzip \
  zip \
  gnupg \
  gpg \
  curl \
  wget \
  lsb-release \
  software-properties-common \
  jq
 
# ─── Python 3.14 (native on Ubuntu 26.04) ─────────────────────────────────────
sudo apt-get install -y \
  python3.14 \
  python3.14-venv \
  python3.14-dev \
  python3.14-full
 
# Bootstrap pip - suppress root warning since this is a VMSS agent
curl -sS https://bootstrap.pypa.io/get-pip.py | \
  sudo python3.14 - --break-system-packages --root-user-action=ignore
 
# Set python3.14 as default using actual binary path
PYTHON314_BIN=$(which python3.14)
 
sudo update-alternatives --install /usr/bin/python3 python3 "$PYTHON314_BIN" 1
sudo update-alternatives --set python3 "$PYTHON314_BIN"
 
# Create unversioned python symlink (needed by DevOps extension internally)
sudo ln -sf "$PYTHON314_BIN" /usr/bin/python
 
# ─── pipx ─────────────────────────────────────────────────────────────────────
sudo python3.14 -m pip install --upgrade pipx \
  --break-system-packages \
  --root-user-action=ignore
 
sudo python3.14 -m pipx ensurepath
 
PIPX_BIN="/root/.local/bin"
 
# Install pip-audit (idempotent-safe)
if ! "$PIPX_BIN/pip-audit" --version >/dev/null 2>&1; then
  pipx install pip-audit
fi
 
# ─── Terraform ────────────────────────────────────────────────────────────────
# Hardcode 'noble' (24.04) — HashiCorp has no 'resolute' (26.04) repo yet
wget -O- https://apt.releases.hashicorp.com/gpg \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
 
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com noble main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list
 
sudo apt-get update
sudo apt-get install -y terraform
 
# ─── Azure CLI ────────────────────────────────────────────────────────────────
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
 
# ─── Pre-create /agent directory for Microsoft.Azure.DevOps extension ─────────
# The DevOps extension requires this directory to exist with open permissions
sudo mkdir -p /agent
sudo chmod 777 /agent
sudo rm -f /agent/.agent.lock
 
# ─── Ensure python symlinks are correct for DevOps extension ──────────────────
# The Microsoft.Azure.DevOps.Pipelines.Agent extension uses python internally
sudo ln -sf "$PYTHON314_BIN" /usr/bin/python
sudo ln -sf "$PYTHON314_BIN" /usr/bin/python3
 
# ─── Final Verification ───────────────────────────────────────────────────────
echo ""
echo "===== FULL VERSION CHECK ====="
echo "OS:        $(lsb_release -d | cut -f2)"
echo "Python3:   $(python3 --version)"
echo "Python:    $(python --version)"
echo "Pip3:      $(pip3 --version)"
echo "Pipx:      $(pipx --version)"
echo "Pip-audit: $($PIPX_BIN/pip-audit --version)"
echo "Terraform: $(terraform version | head -1)"
echo "Azure CLI: $(az version --query '"azure-cli"' -o tsv)"
echo ""
echo "===== AGENT DIR CHECK ====="
ls -la /agent
echo ""
echo "===== PYTHON SYMLINKS CHECK ====="
which python && python --version
which python3 && python3 --version
echo ""
echo "===== SUCCESS ====="
