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

# =========================
# Install Python 3.14
# =========================

PYTHON_VERSION="3.14.0"

sudo apt-get install -y \
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
  uuid-dev

cd /tmp

wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz

tar -xzf Python-${PYTHON_VERSION}.tgz

cd Python-${PYTHON_VERSION}

./configure

make -j"$(nproc)"

sudo make altinstall

# Verify Python 3.14
/usr/local/bin/python3.14 --version

# Optional symlink
sudo ln -sf /usr/local/bin/python3.14 /usr/bin/python3.14

# Make Python 3.14 available in PATH for Azure Pipelines agents
echo 'export PATH=/usr/local/bin:$PATH' | sudo tee /etc/profile.d/python314.sh > /dev/null
sudo chmod +x /etc/profile.d/python314.sh

# Upgrade pip for Python 3.14
/usr/local/bin/python3.14 -m ensurepip --upgrade
/usr/local/bin/python3.14 -m pip install --upgrade pip setuptools wheel

echo "===== Versions ====="
/usr/bin/python3 --version
/usr/local/bin/python3.14 --version
pipx --version
$PIPX_BIN/pip-audit --version
terraform -version
az version

echo "===== SUCCESS ====="
