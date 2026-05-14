#!/usr/bin/env bash
set -euxo pipefail

# =========================================================
# Ubuntu 22.04 VMSS bootstrap for Azure DevOps agents
# - Keeps system Python 3.10 intact
# - Installs Python 3.12 alongside system Python
# - Installs Azure CLI
# - Installs Terraform
# =========================================================

PYTHON_VERSION="3.12.13"

# =========================================================
# Configure apt repositories
# =========================================================

sudo add-apt-repository universe -y || true
sudo add-apt-repository multiverse -y || true

# Optional: Use Azure Ubuntu mirror
sudo sed -i 's|http://archive.ubuntu.com/ubuntu/|http://azure.archive.ubuntu.com/ubuntu/|g' /etc/apt/sources.list
sudo sed -i 's|http://security.ubuntu.com/ubuntu/|http://azure.archive.ubuntu.com/ubuntu/|g' /etc/apt/sources.list

sudo rm -rf /var/lib/apt/lists/*
sudo apt-get clean

sudo DEBIAN_FRONTEND=noninteractive apt-get update -y

# =========================================================
# Install system dependencies
# =========================================================

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  build-essential \
  software-properties-common \
  lsb-release \
  curl \
  wget \
  unzip \
  zip \
  jq \
  gnupg \
  gpg \
  xz-utils \
  uuid-dev \
  zlib1g-dev \
  libncurses5-dev \
  libgdbm-dev \
  libnss3-dev \
  libssl-dev \
  libreadline-dev \
  libffi-dev \
  libsqlite3-dev \
  libbz2-dev \
  liblzma-dev \
  tk-dev

# =========================================================
# Install Python 3.12 from source
# =========================================================

install_python312() {
  cd /tmp

  wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz

  tar -xzf Python-${PYTHON_VERSION}.tgz

  cd Python-${PYTHON_VERSION}

  ./configure \
    --enable-optimizations \
    --with-ensurepip=install

  make -j"$(nproc)"

  # IMPORTANT:
  # altinstall prevents overwriting system python3
  sudo make altinstall

  # Verify installation
  /usr/local/bin/python3.12 --version
  /usr/local/bin/pip3.12 --version
}

# =========================================================
# Install Terraform
# =========================================================

install_terraform() {
  wget -O- https://apt.releases.hashicorp.com/gpg \
    | gpg --dearmor \
    | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    | sudo tee /etc/apt/sources.list.d/hashicorp.list

  sudo DEBIAN_FRONTEND=noninteractive apt-get update -y

  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y terraform

  terraform version
}

# =========================================================
# Install Azure CLI
# =========================================================

install_azure_cli() {
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

  az version
}

# =========================================================
# Install Azure DevOps extension
# =========================================================

install_azure_devops_extension() {
  az extension add --name azure-devops --yes
}

# =========================================================
# Execute installations
# =========================================================

install_python312
install_azure_cli
install_terraform
install_azure_devops_extension

echo "========================================="
echo "Bootstrap completed successfully"
echo "System Python:"
python3 --version
echo "Custom Python:"
/usr/local/bin/python3.12 --version
echo "========================================="
