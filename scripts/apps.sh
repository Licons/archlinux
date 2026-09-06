#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

read -p "Your Nvidia GPU is 10xx (y or n): " GPU

case $GPU in
    y)

        echo
        echo
        echo "##################################################"
        echo "###                SETUP YAY                   ###"
        echo "##################################################"
        echo
        echo

        git clone https://aur.archlinux.org/yay /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        cd $SCRIPT_DIR

        echo
        echo
        echo "##################################################"
        echo "###              INSTALL NVIDIA                ###"
        echo "##################################################"
        echo
        echo

        yay -S --noconfirm \
            nvidia-580xx-dkms nvidia-580xx-settings \
            nvidia-580xx-utils opencl-nvidia-580xx \
            lib32-nvidia-580xx-utils opencl-nvidia-580xx
        ;;
    *)
        echo "No option!"
        ;;
esac

echo
echo
echo "##################################################"
echo "###          INSTALL DOTNET 8+9+10             ###"
echo "##################################################"
echo
echo

net8="8.0.422"
net9="9.0.315"
net10="10.0.301"

wget -P ~/Downloads https://builds.dotnet.microsoft.com/dotnet/Sdk/$net8/dotnet-sdk-$net8-linux-x64.tar.gz
wget -P ~/Downloads https://builds.dotnet.microsoft.com/dotnet/Sdk/$net9/dotnet-sdk-$net9-linux-x64.tar.gz
wget -P ~/Downloads https://builds.dotnet.microsoft.com/dotnet/Sdk/$net10/dotnet-sdk-$net10-linux-x64.tar.gz

sudo mkdir -p /usr/share/dotnet
sudo tar -xzf ~/Downloads/dotnet-sdk-$net8-linux-x64.tar.gz -C /usr/share/dotnet/
sudo tar -xzf ~/Downloads/dotnet-sdk-$net9-linux-x64.tar.gz -C /usr/share/dotnet/
sudo tar -xzf ~/Downloads/dotnet-sdk-$net10-linux-x64.tar.gz -C /usr/share/dotnet/
sudo ln -sf /usr/share/dotnet/dotnet /usr/bin/dotnet

dotnet --info
dotnet dev-certs https --trust

dotnet tool install -g dotnet-ef
dotnet tool install -g dotnet-sonarscanner

rm ~/Downloads/*.tar.gz

echo
echo
echo "##################################################"
echo "###          INSTALL NPM PACKAGE               ###"
echo "##################################################"
echo
echo

sudo npm i -g bash-language-server

#sudo npm config set allow-scripts=@openapitools/openapi-generator-cli --location=user
#sudo npm i -g @openapitools/openapi-generator-cli
#sudo openapi-generator-cli version-manager set latest

echo
echo
echo "##################################################"
echo "###        DOWNLOAD ANOTHER REDIS              ###"
echo "##################################################"
echo
echo

ANOTHER_VERSION="1.7.4"
ANOTHER_REDIS="Another-Redis-Desktop-Manager-linux-$ANOTHER_VERSION-x86_64.AppImage"
sudo pacman -S --noconfirm fuse2
mkdir -p ~/AppImages
wget -P ~/AppImages https://github.com/qishibo/AnotherRedisDesktopManager/releases/download/v$ANOTHER_VERSION/$ANOTHER_REDIS
cp $SCRIPT_DIR/../pictures/another_redis.png ~/AppImages/another_redis.png

sudo chmod +x ~/AppImages/$ANOTHER_REDIS
mkdir -p ~/.local/share/applications
cat <<EOF > ~/.local/share/applications/another-redis.desktop
[Desktop Entry]
Name=Another Redis Desktop Manager
Exec=$HOME/AppImages/$ANOTHER_REDIS
Icon=$HOME/AppImages/another_redis.png
Type=Application
Categories=Utility;
EOF


echo
echo
echo "##################################################"
echo "###                   OTHERS                   ###"
echo "##################################################"
echo
echo

#curl -fsSL https://claude.ai/install.sh | bash
#claude mcp add chrome-devtools npx chrome-devtools-mcp@latest

curl -LsSf https://astral.sh/uv/install.sh | sh
uv tool install graphifyy
graphify install

#sudo npm config set allow-scripts=opencode-ai --location=user
#sudo npm install -g opencode-ai

sudo npm config set allow-scripts=yarn --location=user
sudo npm install -g yarn@1.22.22

echo
echo
echo "##################################################"
echo "###                   CHROME                   ###"
echo "##################################################"
echo
echo

cd ~/Downloads
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
ar x google-chrome-stable_current_amd64.deb
tar -xf data.tar.xz

sudo cp -r opt/google /opt/
sudo mkdir -p ~/.local/share/applications
sudo cp -r usr/share/applications/google-chrome.desktop ~/.local/share/applications/
sudo ln -s /opt/google/chrome/google-chrome /usr/bin/google-chrome-stable

echo
echo "### INSTALLED APPS ###"
