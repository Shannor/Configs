#!/bin/bash
# install home brew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew update
brew doctor

# Helps read JSON data
brew install jq

# Git worktree manager (wt)
brew install worktrunk

# Setup for zsh and themes
cp .zshrc $HOME/.zshrc
brew install zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
wt config shell install --yes zsh
# chsh -s $(which zsh)
# git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k


brew cask install alfred

# Tools that might now have Brew
# AltTab
# Homerow
# satt, my personal CLI for fun stuff.

brew cleanup

# Node is managed with asdf; global npm CLIs must be installed through it
brew install asdf
asdf plugin add nodejs 2>/dev/null || true
asdf install nodejs latest:22
asdf set --home nodejs latest:22 2>/dev/null || asdf global nodejs latest:22

# Cloudflare CLI (beta), used by the cloudflare-cli skill
npm i -g cf
asdf reshim nodejs

# Link custom CLI utilities into ~/.local/bin
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$HOME/.local/bin"
for bin_file in "$SCRIPT_DIR"/bin/*; do
  [ -f "$bin_file" ] && ln -sf "$bin_file" "$HOME/.local/bin/$(basename "$bin_file")"
done

# Setup AI agent skills
"$SCRIPT_DIR/../ai/setup-skills.sh"
