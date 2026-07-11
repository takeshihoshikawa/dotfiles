#!/usr/bin/env bash
set -e

sudo apt update

sudo apt install -y \
  git \
  tmux \
  stow \
  htop \
  rsync \
  wget \
  curl \
  unzip \
  zip \
  cifs-utils \
  build-essential \
  cmake \
  openssh-server \
  pkg-config \
  software-properties-common \
  dirmngr \
  gpg \
  pandoc \
  tree \
  libgdal-dev \
  libgeos-dev \
  libproj-dev \
  libudunits2-dev \
  libcurl4-openssl-dev \
  libssl-dev \
  libxml2-dev \
  libfreetype6-dev \
  fonts-noto-cjk

curl -fsSL https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc \
  | gpg --dearmor | sudo tee /usr/share/keyrings/cran.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/cran.gpg] https://cloud.r-project.org/bin/linux/ubuntu noble-cran40/" \
  | sudo tee /etc/apt/sources.list.d/cran-r.list

sudo apt update

sudo apt install -y r-base r-base-dev

sudo mkdir -p /work/projects
sudo mkdir -p /work/data
sudo mkdir -p /work/tmp
sudo chown -R $USER:$USER /work

# R の重い解析処理でメモリに余裕があるうちからスワップへ逃げないよう抑制する
# (デフォルト 60 は汎用デスクトップ向けで、解析ワークロードには積極的すぎる)
echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-swappiness.conf > /dev/null
sudo sysctl --system > /dev/null

sudo systemctl enable ssh
sudo systemctl start ssh

mkdir -p ~/R/library

cat << 'EOF' >> ~/.Rprofile
dir.create("~/R/library", recursive = TRUE, showWarnings = FALSE)
.libPaths(c("~/R/library", .libPaths()))
EOF

R -q -e "options(repos='https://cloud.r-project.org'); install.packages('renv')"

# uv (Python パッケージマネージャ。data-analysis-coding-conventions.md の標準ツール)
curl -LsSf https://astral.sh/uv/install.sh | sh

if [ ! -d ~/dotfiles ]; then
  git clone https://github.com/takeshihoshikawa/dotfiles.git ~/dotfiles
else
  echo "~/dotfiles already exists. Skipping clone."
fi

mkdir -p ~/.ssh && chmod 700 ~/.ssh
stow -d ~/dotfiles -t ~ git ssh claude codex

# gh (GitHub CLI)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | sudo tee /etc/apt/sources.list.d/github-cli.list
sudo apt update && sudo apt install -y gh

# awscli v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip /tmp/awscliv2.zip -d /tmp
sudo /tmp/aws/install
rm -rf /tmp/aws /tmp/awscliv2.zip

# Docker + NVIDIA Container Toolkit（GPU コンテナでの解析ワークロード用）
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor | sudo tee /etc/apt/keyrings/docker.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker "$USER"

curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
  | gpg --dearmor | sudo tee /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg > /dev/null
curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null
sudo apt update
sudo apt install -y nvidia-container-toolkit
# GPU ドライバは末尾の `ubuntu-drivers autoinstall` で入るため、その後に
# `sudo nvidia-ctk runtime configure --runtime=docker && sudo systemctl restart docker` が必要

# quarto + texlive-full（論文原稿の PDF/DOCX レンダリング用。texlive-full は数GB级のダウンロード）
QUARTO_VERSION=$(curl -fsSL https://api.github.com/repos/quarto-dev/quarto-cli/releases/latest | grep -oP '"tag_name": "v\K[^"]+')
curl -fsSL -o /tmp/quarto.deb "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb"
sudo dpkg -i /tmp/quarto.deb
rm -f /tmp/quarto.deb
sudo apt install -y texlive-full

curl -fsSL https://tailscale.com/install.sh | sh

# NAS (QNAP Public share) を Tailscale 経由で CIFS automount。
# 資格情報テンプレを作るだけで、パスワード記入までマウントは失敗する（スクリプト末尾の NOTE 参照）。
# tailscale 導入後に呼ぶ（automount は tailscaled.service に依存）。失敗しても bootstrap 全体は止めない。
bash "$(dirname "$0")/setup_nas_mount.sh" || echo "WARN: setup_nas_mount.sh failed — 後で個別に実行してください"

# Claude Code CLI (native installer, no Node.js required)
curl -fsSL https://claude.ai/install.sh | sh

sudo ubuntu-drivers autoinstall

echo "NOTE: ~/.claude/settings.local.json is gitignored and not stowed."
echo "      Create it manually for local-only Claude settings."
echo "NOTE: reboot 後、GPU ドライバ有効化を確認してから以下で Docker の GPU runtime を設定:"
echo "      sudo nvidia-ctk runtime configure --runtime=docker && sudo systemctl restart docker"
echo "Setup finished. Please reboot manually"
