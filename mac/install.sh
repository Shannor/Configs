#!/bin/bash
# install home brew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew update
brew doctor

# Replacement for curl
brew install httpie
# Helps read JSON data
brew install jq
brew install golang
brew install git

# Setup for zsh and themes
cp .zshrc $HOME/.zshrc
brew install zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
# chsh -s $(which zsh)
# git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k

# Scala needs Java first

brew cask install alfred
brew cask install docker
brew cask install iterm2
brew cask install insomnia

brew cleanup
