#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo
echo
echo "##################################################"
echo "###          INSTALL DOTNET 8+9+10             ###"
echo "##################################################"
echo
echo

net8="8.0.425"
net9="9.0.318"
net10="10.0.401"

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
dotnet tool install -g microsoft.sqlpackage

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

sudo npm config set allow-scripts=yarn --location=user
sudo npm install -g yarn@1.22.22

# go install github.com/microsoft/go-sqlcmd@latest

sqlcmd
sqlcmd
echo
echo
echo "##################################################"
echo "###        DOWNLOAD ANOTHER REDIS              ###"
echo "##################################################"
echo
echo

cd $SCRIPT_DIR
ANOTHER_VERSION="1.7.4"
ANOTHER_REDIS="Another-Redis-Desktop-Manager-linux-$ANOTHER_VERSION-x86_64.AppImage"
mkdir -p ~/AppImages
wget -P ~/AppImages https://github.com/qishibo/AnotherRedisDesktopManager/releases/download/v$ANOTHER_VERSION/$ANOTHER_REDIS
cp ./pictures/another_redis.png ~/AppImages/another_redis.png

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
echo
echo "##################################################"
echo "###                 MS TEAMS                   ###"
echo "##################################################"
echo
echo

flatpak remote-add --if-not-exists flathub https://flathub.org
flatpak install flathub com.github.IsmaelMartinez.teams_for_linux

echo
echo
echo "##################################################"
echo "###                   AGENTS                   ###"
echo "##################################################"
echo
echo

curl -fsSL https://claude.ai/install.sh | bash
claude mcp add chrome-devtools npx chrome-devtools-mcp@latest

curl -LsSf https://astral.sh/uv/install.sh | sh
uv tool install graphifyy
graphify install

curl -fsSL https://opencode.ai/install | bash

curl -fsSL https://chatgpt.com/codex/install.sh | sh

echo
echo "### INSTALLED APPS ###"
