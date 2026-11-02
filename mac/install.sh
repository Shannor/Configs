#!/bin/bash
# install home brew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew update
brew doctor

# Helps read JSON data
brew install jq

# Setup for zsh and themes
cp .zshrc $HOME/.zshrc
brew install zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
# chsh -s $(which zsh)
# git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k


brew cask install alfred

# Tools that might now have Brew
# AltTab
# Homerow
# satt, my personal CLI for fun stuff.

brew cleanup
