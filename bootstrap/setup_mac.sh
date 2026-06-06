#!/usr/bin/env bash
set -e

echo "=== macOS Setup ==="

echo "--- Homebrew ---"
if ! command -v brew &> /dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew already installed. Skipping."
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

echo "--- dotfiles ---"
if [ ! -d ~/dotfiles ]; then
  git clone https://github.com/takeshihoshikawa/dotfiles.git ~/dotfiles
else
  echo "~/dotfiles already exists. Skipping clone."
fi

echo "--- Directories ---"
mkdir -p ~/.ssh && chmod 700 ~/.ssh
mkdir -p ~/.aws
mkdir -p ~/work/{projects,data,tmp}
ln -sfn ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/main ~/vault

echo "--- Brewfile ---"
sudo -v
brew bundle --file ~/dotfiles/brew/Brewfile

echo "--- stow ---"
cd ~/dotfiles
stow ssh aws git zsh brew claude codex vscode

echo "--- launchd (daily-report reminder) ---"
SCRIPT_DST="$HOME/.local/bin/daily-report-reminder.sh"
PLIST_DST="$HOME/Library/LaunchAgents/com.takeshi.daily-report-reminder.plist"
mkdir -p "$HOME/.local/bin" "$HOME/Library/LaunchAgents"
cp ~/dotfiles/launchd/daily-report-reminder.sh "$SCRIPT_DST"
chmod +x "$SCRIPT_DST"
sed "s|__SCRIPT_PATH__|$SCRIPT_DST|g" \
  ~/dotfiles/launchd/com.takeshi.daily-report-reminder.plist > "$PLIST_DST"
launchctl bootout "gui/$(id -u)" "$PLIST_DST" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_DST"

echo "--- R packages ---"
R -q -e "options(repos='https://cloud.r-project.org'); install.packages('renv')"

echo "=== Setup complete ==="
