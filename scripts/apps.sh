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
dotnet dev-certs https --trust || true

dotnet tool install -g dotnet-ef
dotnet tool install -g dotnet-sonarscanner
dotnet tool install -g microsoft.sqlpackage

rm ~/Downloads/dotnet-sdk-{$net8,$net9,$net10}-linux-x64.tar.gz
cd $SCRIPT_DIR

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

echo
echo
echo "##################################################"
echo "###                   CHROME                   ###"
echo "##################################################"
echo
echo

# Giải nén trong thư mục tạm: không đụng file của anh trong ~/Downloads.
CHROME_TMP="$(mktemp -d)"
cd "$CHROME_TMP"
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
ar x google-chrome-stable_current_amd64.deb
tar -xf data.tar.xz

sudo cp -r opt/google /opt/
cp usr/share/applications/google-chrome.desktop ~/.local/share/applications/
sudo ln -sf /opt/google/chrome/google-chrome /usr/bin/google-chrome-stable
cd "$SCRIPT_DIR"
rm -rf "$CHROME_TMP"

echo
echo
echo "##################################################"
echo "###                 MS TEAMS                   ###"
echo "##################################################"
echo
echo

# Gói flatpak của Arch đã có sẵn remote flathub (system).
flatpak install -y flathub com.github.IsmaelMartinez.teams_for_linux
flatpak override --user --own-name=org.freedesktop.StatusNotifierItem-2-1 com.github.IsmaelMartinez.teams_for_linux

echo
echo
echo "##################################################"
echo "###                   AGENTS                   ###"
echo "##################################################"
echo
echo

curl -fsSL https://claude.ai/install.sh | bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
#~ claude mcp add chrome-devtools npx chrome-devtools-mcp@latest

curl -LsSf https://astral.sh/uv/install.sh | sh
uv tool install graphifyy
graphify install

echo
echo "### INSTALLED APPS ###"
