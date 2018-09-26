
sudo apt -y install htop
sudo apt -y install ctop
sudo apt -y install docker.io
sudo apt -y install docker-compose
sudo apt -y install golang
sudo apt -y install terminator
# Provide-y sd ubuntu customizations
sudo apt -y install gnome-tweak-tool

# Snap installs
sudo snap -y install intellij-idea-ultimate --classic
sudo snap -y install vscode
sudo snap -y install node
sudo snap -y install kotlin
sudo snap -y install postman
sudo snap -y install insomnia
sudo snap -y install kotlin-native


# Setup for ZSH shell
sudo apt-get -y install zsh
sudo apt-get -y install git-core

wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh
chsh -s `which zsh`

sudo groupadd docker
sudo usermod -aG docker $USER

# Shutdown for any restarts needed.
sudo shutdown -r 0