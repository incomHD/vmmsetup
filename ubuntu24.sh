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
 
# ─── Python 3.14 build dependencies ───────────────────────────────────────────
sudo apt-get install -y \
  build-essential \
  libssl-dev \
  zlib1g-dev \
  libbz2-dev \
  libreadline-dev \
  libsqlite3-dev \
  libffi-dev \
  liblzma-dev \
  libncurses5-dev \
  libgdbm-dev \
  libnss3-dev \
  tk-dev \
  uuid-dev
 
# ─── Compile Python 3.14 from source ──────────────────────────────────────────
# System python3 (3.10) stays untouched — extension needs it
cd /tmp
wget https://www.python.org/ftp/python/3.14.0/Python-3.14.0.tar.xz
tar -xf Python-3.14.0.tar.xz
cd Python-3.14.0
./configure --enable-optimizations --prefix=/usr/local
make -j$(nproc)
sudo make altinstall       # altinstall = does NOT overwrite system python3
 
# Verify both pythons coexist
/usr/bin/python3 --version          # System python3 = 3.10 (for extension)
/usr/local/bin/python3.14 --version # Your python3.14
 
# ─── Make python3.14 easy to use in pipelines ─────────────────────────────────
# Add convenience symlinks in /usr/local/bin (won't touch /usr/bin/python3)
sudo ln -sf /usr/local/bin/python3.14 /usr/local/bin/python3.14
sudo ln -sf /usr/local/bin/pip3.14 /usr/local/bin/pip3.14
 
# Install pipx using python3.14
/usr/local/bin/python3.14 -m pip install --upgrade pipx
/usr/local/bin/python3.14 -m pipx ensurepath
 
PIPX_BIN="/root/.local/bin"
 
# Install pip-audit (idempotent-safe)
if ! "$PIPX_BIN/pip-audit" --version >/dev/null 2>&1; then
  /usr/local/bin/python3.14 -m pipx install pip-audit
fi
 
# ─── Terraform ────────────────────────────────────────────────────────────────
wget -O- https://apt.releases.hashicorp.com/gpg \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
 
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list
 
sudo apt-get update
sudo apt-get install -y terraform
 
# ─── Azure CLI ────────────────────────────────────────────────────────────────
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
 
# ─── Pre-create /agent directory for DevOps extension ─────────────────────────
sudo mkdir -p /agent
sudo chmod 777 /agent
sudo rm -f /agent/.agent.lock
 
# ─── Cleanup build files to save disk space ───────────────────────────────────
sudo rm -rf /tmp/Python-3.14.0 /tmp/Python-3.14.0.tar.xz
 
# ─── Final Verification ───────────────────────────────────────────────────────
echo ""
echo "===== FULL VERSION CHECK ====="
echo "OS:           $(lsb_release -d | cut -f2)"
echo "System Python:$(  /usr/bin/python3 --version)   ← kept for DevOps extension"
echo "Python 3.14:  $(/usr/local/bin/python3.14 --version)   ← use in pipelines"
echo "Pip 3.14:     $(/usr/local/bin/pip3.14 --version)"
echo "Pipx:         $(pipx --version)"
echo "Pip-audit:    $($PIPX_BIN/pip-audit --version)"
echo "Terraform:    $(terraform version | head -1)"
echo "Azure CLI:    $(az version --query '"azure-cli"' -o tsv)"
echo ""
echo "===== AGENT DIR CHECK ====="
ls -la /agent
echo ""
echo "===== SUCCESS ====="
