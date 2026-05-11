#!/usr/bin/env bash
set -euxo pipefail

# -----------------------------
# Fix apt repos and mirrors
# -----------------------------

# Enable universe & multiverse repos
sudo add-apt-repository universe -y || true
sudo add-apt-repository multiverse -y || true

# Use Azure mirror
sudo sed -i 's|http://archive.ubuntu.com/ubuntu/|http://azure.archive.ubuntu.com/ubuntu/|g' /etc/apt/sources.list
sudo sed -i 's|http://security.ubuntu.com/ubuntu/|http://azure.archive.ubuntu.com/ubuntu/|g' /etc/apt/sources.list

# Reset and update apt cache
sudo rm -rf /var/lib/apt/lists/*
sudo apt-get clean
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y

# -----------------------------
# Install common tools
# -----------------------------
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  unzip \
  zip \
  gnupg \
  gpg \
  curl \
  wget \
  lsb-release \
  software-properties-common \
  jq \
  build-essential \
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
  tk-dev \
  uuid-dev \
  xz-utils

# -----------------------------
# Install Python 3.14
# -----------------------------
function install_python314() {(
  PYTHON_VERSION="3.14.0"

  cd /tmp

  wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz

  tar -xzf Python-${PYTHON_VERSION}.tgz

  cd Python-${PYTHON_VERSION}

  ./configure \
    --enable-optimizations \
    --with-ensurepip=install

  make -j"$(nproc)"

  # altinstall prevents overwriting system python
  sudo make altinstall

  # Verify install
  /usr/local/bin/python3.14 --version
  /usr/local/bin/pip3.14 --version

  # Optional symlink
  sudo ln -sf /usr/local/bin/python3.14 /usr/bin/python3.14
  sudo ln -sf /usr/local/bin/pip3.14 /usr/bin/pip3.14
)}

# -----------------------------
# Install Terraform
# -----------------------------
function install_terraform() {(
  wget -O- https://apt.releases.hashicorp.com/gpg \
    | gpg --dearmor \
    | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    | sudo tee /etc/apt/sources.list.d/hashicorp.list

  sudo DEBIAN_FRONTEND=noninteractive apt-get update -y

  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y terraform
)}

# -----------------------------
# Install Azure CLI
# -----------------------------
function install_azcli() {(
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
)}

# -----------------------------
# Execute installers
# -----------------------------
install_python314
install_azcli
install_terraform

# Add Azure DevOps CLI extension
az extension add --name azure-devops
