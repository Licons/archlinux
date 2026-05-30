#!/bin/bash

set -e

read -p "Enter your username: " username
read -p "Enter your GIT username: " gituser
read -p "Enter your GIT email: " gitemail

chsh -s /usr/bin/fish $username

echo
echo
echo "##################################################"
echo "###            CONFIGURE FISH                  ###"
echo "##################################################"
echo
echo

cat <<EOF > ./fish/config.fish
if status is-interactive
    fastfetch
end

set -g fish_greeting
set -gx PATH \$PATH /home/$username/.dotnet/tools

set -x DOTNET_CLI_TELEMETRY_OPTOUT 1
set -x LC_ALL C.UTF-8
EOF

mkdir -p ~/.config/fish
cp -frv ./fish/* ~/.config/fish/

echo
echo
echo "##################################################"
echo "###            CONFIGURE FCITX                 ###"
echo "##################################################"
echo
echo

cat <<EOF > ~/.xprofile
# Fcitx5 input method
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS="@im=fcitx"
export INPUT_METHOD=fcitx
EOF

mkdir -p ~/.config/environment.d
cat <<EOF > ~/.config/environment.d/im.conf
# Fcitx5 input method
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
INPUT_METHOD=fcitx
EOF

echo
echo
echo "##################################################"
echo "###          CONFIGURE GIT CRED                ###"
echo "##################################################"
echo
echo

git config --global user.name "$gituser"
git config --global user.email "$gitemail"
git config --global credential.helper store
cat <<EOF > ~/.git-credentials
https://TripOTAEcoSys@dev.azure.com
https://licons@github.com
EOF

echo
echo
echo "##################################################"
echo "###          CONFIGURE THEMES                  ###"
echo "##################################################"
echo
echo

mkdir -p ~/.icons
cp -frv ./cursors/* ~/.icons/

mkdir -p ~/.themes
cp -frv ./themes/* ~/.themes/

mkdir -p ~/.config/environment.d
echo "MANGOHUD=1">~/.config/environment.d/mangohud.conf

mkdir -p ~/.config/MangoHud
cat <<EOF > ~/.config/MangoHud/MangoHud.conf
legacy_layout=false
position=top-right

fps
cpu_stats
gpu_stats
cpu_temp
gpu_temp
EOF

echo
echo
echo "##################################################"
echo "###          CONFIGURE KVANTUM                 ###"
echo "##################################################"
echo
echo

sudo cp -frv ./Kvantum/* /usr/share/Kvantum/

sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 9000/tcp

# echo
# echo
# echo "##################################################"
# echo "###          CONFIGURE PLASMOIDS               ###"
# echo "##################################################"
# echo
# echo
#
# mkdir -p ~/.local/share/plasma/plasmoids/org.kde.plasma.taskmanager/
#cp -frv /usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/* ~/.local/share/plasma/plasmoids/org.kde.plasma.taskmanager/
#cp -fv ./plasmoids/org.kde.plasma.taskmanager/Task.qml ~/.local/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/ui/Task.qml

echo
echo "### DONE ###"
