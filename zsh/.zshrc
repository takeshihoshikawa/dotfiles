export PATH="/opt/homebrew/bin:$PATH:$HOME/bin"
export PS1='%F{cyan}%n@%m%f %F{green}%1~%f %# '
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

export GOOGLE_OAUTH_CREDENTIALS="$HOME/.config/gcp/gcp-oauth.keys.json"

# OpenAlex API キー（実値は git 外の ~/.config/openalex/api_key・権限 600）。
# キーチェーンにしないのは、SSH 越しではロックされていて読めないため
[[ -r "$HOME/.config/openalex/api_key" ]] && export OPENALEX_API_KEY="$(<"$HOME/.config/openalex/api_key")"
export PATH="$HOME/.local/bin:$PATH"

alias cc='cd ~/work/projects/admin && claude'
