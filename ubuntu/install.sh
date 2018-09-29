# Move other configs to $HOME
cp .gitconfig ~
cp .zshrc ~
cp .gitignore_global ~

# Apt installs
sudo apt update
sudo apt -y install htop
sudo apt -y install docker.io
sudo apt -y install docker-compose
sudo apt -y install golang
sudo apt -y install terminator
sudo apt -y install gnome-tweak-tool
sudo apt -y install curl
sudo apt -y install vim
sudo apt -y install python-pip
sudo apt -y install python3-pip
sudo apt -y install vim
sudo apt -y install npm

# Snap installs
sudo snap install intellij-idea-ultimate --classic
sudo snap install vscode
sudo snap install node
sudo snap install kotlin
sudo snap install postman
sudo snap install insomnia
sudo snap install kotlin-native


# Setup for ZSH shell
sudo apt-get -y install zsh
sudo apt-get -y install git

wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh
chsh -s `which zsh`

pip install --user powerline-status
git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k
wget https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf
wget https://github.com/powerline/powerline/raw/develop/font/10-powerline-symbols.conf
mkdir -p  ~/.local/share/fonts/
mv PowerlineSymbols.otf ~/.local/share/fonts/
fc-cache -vf ~/.local/share/fonts/
mkdir -p ~/.config/fontconfig/conf.d/
mv 10-powerline-symbols.conf ~/.config/fontconfig/conf.d/

# Setup for Docker
sudo groupadd docker
sudo usermod -aG docker $USER

#Setup for GCP-cli
export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update && sudo apt-get -y install google-cloud-sdk
