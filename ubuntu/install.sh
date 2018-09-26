
sudo apt install htop
sudo apt install ctop
sudo apt install docker.io
sudo apt install docker-compose
sudo apt install golang
# Providesd ubuntu customizations
sudo apt install gnome-tweak-tool

# Snap installs
sudo snap install intellij-idea-ultimate --classic
sudo snap install vscode
sudo snap install node
sudo snap install kotlin
sudo snap install postman
sudo snap install insomnia
sudo snap install kotlin-native
sudo snap install slack
sudo snap install discord


# Setup for ZSH shell
sudo apt-get install zsh
sudo apt-get install git-core

wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh
chsh -s `which zsh`


# Shutdown for any restarts needed.
sudo shutdown -r 0