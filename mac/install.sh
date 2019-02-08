#!/bin/bash

# TODO: Add question of if this is going to use bash or zsh.
# TODO: Add commands to make the $GOPATH for me and add it to the env .zshrc

# install home brew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew update
brew doctor
brew tap caskroom/cask  

brew install node
brew install pyenv
brew install jenv
brew install httpie
brew install htop
brew install ctop
brew install python3
brew install jq
brew install docker-compose
brew install golang
brew install git
# brew install bash-completion  #Only if bash install

cp .bash_profile $HOME/.bash_profile
# Setup for zsh and themes
cp .zshrc $HOME/.zshrc
brew install zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
# chsh -s $(which zsh)
# git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k

# Scala needs Java first
brew cask install java
brew install scala
brew install sbt

brew cask install alfred
brew cask install docker
brew cask install intellij-idea
brew cask install android-studio
brew cask install visual-studio-code
brew cask install authy
brew cask install iterm2
brew cask install postman
brew cask install insomnia
#  Add pyenv init to bash profile
echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.bash_profile
echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.zshrc
echo 'export PATH="$HOME/.jenv/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(jenv init -)"' >> ~/.bash_profile
brew cleanup
