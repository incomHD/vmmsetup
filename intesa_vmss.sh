export DEBIAN_FRONTEND=noninteractive

sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

sudo apt-get update --allow-releaseinfo-change -o Acquire::Retries=5

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
  python3-setuptools \
  pipx

# Directly use full path for reliability
PIPX_BIN="/root/.local/bin"

# Install pip-audit (idempotent-safe)
if ! $PIPX_BIN/pip-audit --version >/dev/null 2>&1; then
  pipx install pip-audit
fi

# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update
sudo apt-get install -y terraform

# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

echo "===== Versions ====="
/usr/bin/python3 --version
pipx --version
$PIPX_BIN/pip-audit --version
terraform -version
az version

echo "===== SUCCESS ====="
