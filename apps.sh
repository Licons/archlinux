#!/bin/bash

set -e

read -p "Your Nvidia GPU is 10xx (y or n): " GPU

echo
echo
echo "##################################################"
echo "###                SETUP YAY                   ###"
echo "##################################################"
echo
echo

git clone https://aur.archlinux.org/yay
cd yay
makepkg -si --noconfirm

echo
echo
echo "##################################################"
echo "###              UPDATE BY YAY                 ###"
echo "##################################################"
echo
echo

cd ..
yay -Syu --noconfirm

echo
echo
echo "##################################################"
echo "###              INSTALL APPS                  ###"
echo "##################################################"
echo
echo

case $GPU in
    y)
        yay -S --noconfirm \
            nvidia-580xx-dkms nvidia-580xx-settings \
            nvidia-580xx-utils lib32-nvidia-580xx-utils \
            vulkan-icd-loader lib32-vulkan-icd-loader
        ;;
    *)
        echo "No option!"
        ;;
esac

yay -S --noconfirm \
  tela-circle-icon-theme \
  kf6-servicemenus-rootactions \
  firefox vlc \
  libreoffice-fresh \
  nodejs npm jdk-openjdk \
  ttf-ms-fonts \
  onedrive onedrivegui teams-for-linux \
  rider dbeaver postman-bin \
  appimagelauncher \
  rclone \
  postgresql

echo
echo
echo "##################################################"
echo "###          INSTALL DOTNET 8+9                ###"
echo "##################################################"
echo
echo

net8="8.0.421"
net9="9.0.314"
net10="10.0.300"

wget -P ~/Downloads https://builds.dotnet.microsoft.com/dotnet/Sdk/$net8/dotnet-sdk-$net8-linux-x64.tar.gz
wget -P ~/Downloads https://builds.dotnet.microsoft.com/dotnet/Sdk/$net9/dotnet-sdk-$net9-linux-x64.tar.gz
wget -P ~/Downloads https://builds.dotnet.microsoft.com/dotnet/Sdk/$net10/dotnet-sdk-$net10-linux-x64.tar.gz

sudo mkdir -p /usr/share/dotnet
sudo tar -xzf ~/Downloads/dotnet-sdk-$net8-linux-x64.tar.gz -C /usr/share/dotnet/
sudo tar -xzf ~/Downloads/dotnet-sdk-$net9-linux-x64.tar.gz -C /usr/share/dotnet/
sudo tar -xzf ~/Downloads/dotnet-sdk-$net10-linux-x64.tar.gz -C /usr/share/dotnet/
sudo ln -sf /usr/share/dotnet/dotnet /usr/bin/dotnet

dotnet --info
dotnet tool update -g linux-dev-certs
dotnet linux-dev-certs install
dotnet dev-certs https --trust

dotnet tool install -g dotnet-ef
dotnet tool install -g dotnet-sonarscanner

echo
echo
echo "##################################################"
echo "###          INSTALL NPM PACKAGE               ###"
echo "##################################################"
echo
echo

sudo npm i -g bash-language-server
sudo npm i -g @openapitools/openapi-generator-cli
sudo openapi-generator-cli version-manager set 7.22.0

echo
echo
echo "##################################################"
echo "###        DOWNLOAD ANOTHER REDIS              ###"
echo "##################################################"
echo
echo

wget -P ~/Downloads https://github.com/qishibo/AnotherRedisDesktopManager/releases/download/v1.7.1/Another-Redis-Desktop-Manager-linux-1.7.1-x86_64.AppImage

echo
echo "### INSTALLED APPS ###"
