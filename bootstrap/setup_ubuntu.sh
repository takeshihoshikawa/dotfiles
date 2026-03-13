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
  build-essential \
  cmake \
  openssh-server \
  pkg-config \
  software-properties-common \
  dirmngr \
  gpg \
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

git clone https://github.com/hoshicurrey/dotfiles.git ~/dotfiles
stow -d ~/dotfiles -t ~ .

curl -fsSL https://tailscale.com/install.sh | sh

sudo ubuntu-drivers autoinstall
echo "Setup finished. Please reboot manually"
