
sudo apt -y install htop
sudo apt -y install ctop
sudo apt -y install docker.io
sudo apt -y install docker-compose
sudo apt -y install golang
sudo apt -y install terminator
# Provide-y sd ubuntu customizations
sudo apt -y install gnome-tweak-tool
sudo apt -y install curl
sudo apt -y install vim

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

sudo groupadd docker
sudo usermod -aG docker $USER

#Install GCP-cli
export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update && sudo apt-get -y install google-cloud-sdk
