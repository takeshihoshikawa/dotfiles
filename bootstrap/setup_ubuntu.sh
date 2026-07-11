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
  libfreetype6-dev

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

sudo systemctl enable ssh
sudo systemctl start ssh

mkdir -p ~/R/library

cat << 'EOF' >> ~/.Rprofile
dir.create("~/R/library", recursive = TRUE, showWarnings = FALSE)
.libPaths(c("~/R/library", .libPaths()))
EOF

R -q -e "options(repos='https://cloud.r-project.org'); install.packages('renv')"

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
echo "Setup finished. Please reboot manually"
