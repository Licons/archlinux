#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIC_PATH=$HOME/Pictures/Wallpapers
KVANTUM_PATH=$HOME/.config/Kvantum
ICONS_PATH=$HOME/.icons
THEMES_PATH=$HOME/.themes

read -p "GIT username: " GIT_USER
read -p "GIT email: " GIT_EMAIL
read -p "Your Nvidia GPU is 10xx (y/n): " GPU
read -p "Using lightdm (y/n): " LIGHTDM
read -p "Using Webkit (y/n): " WEBKIT

chsh -s /usr/bin/fish $USER

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

        echo
        echo
        echo "##################################################"
        echo "###              INSTALL NVIDIA                ###"
        echo "##################################################"
        echo
        echo

        cd $SCRIPT_DIR
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
echo "###            CONFIGURE FISH                  ###"
echo "##################################################"
echo
echo

mkdir -p ~/.config/fish
cat <<EOF > ~/.config/fish/config.fish
if status is-interactive
    fastfetch
end

set -g fish_greeting
set -gx PATH /usr/local/bin \$HOME/.dotnet/tools \$HOME/.local/bin
set -Ux SSL_CERT_DIR "$HOME/.aspnet/dev-certs/trust:/etc/ssl/certs"
set -x DOTNET_CLI_TELEMETRY_OPTOUT 1
set -x LC_ALL C.UTF-8
EOF

mkdir -p ~/.config/fish/functions/
cat <<EOF > ~/.config/fish/functions/fish_prompt.fish
function fish_prompt
    set_color purple
    echo (pwd)
    set_color green
    echo -n '> '
    set_color normal
end
EOF

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
echo "###             CONFIGURE GIT                  ###"
echo "##################################################"
echo
echo

cat <<EOF > ~/.gitconfig
[user]
	name = $GIT_USER
	email = $GIT_EMAIL
[credential]
	helper = store
[core]
	autocrlf = input
[filter "lfs"]
	smudge = git-lfs smudge -- %f
	process = git-lfs filter-process
	required = true
	clean = git-lfs clean -- %f
EOF

cat <<EOF > ~/.git-credentials
https://Loyalstar@dev.azure.com
https://licons@github.com
EOF

echo
echo
echo "##################################################"
echo "###          CONFIGURE UFW                     ###"
echo "##################################################"
echo
echo

# sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow from 192.168.1.0/24 to any port 137,138 proto udp
sudo ufw allow from 192.168.1.0/24 to any port 139,445 proto tcp
sudo ufw enable

echo
echo
echo "##################################################"
echo "###          CONFIGURE OTHERS                  ###"
echo "##################################################"
echo
echo

git clone https://github.com/vinceliuice/Layan-kde /tmp/layan
cd /tmp/layan
bash install.sh

cd $SCRIPT_DIR

mkdir -p $PIC_PATH
cp pictures/train.png $PIC_PATH

mkdir -p $KVANTUM_PATH
7z x files/Kvantum.7z -o"$KVANTUM_PATH" -aoa -bb1

mkdir -p $ICONS_PATH
tar -xvf files/Layan-white-cursors.tar.xz -C $ICONS_PATH
tar -xvf files/Bibata-Modern-Ice.tar.xz -C $ICONS_PATH
tar -xvf files/Future-cursors.tar.gz -C $ICONS_PATH
tar -xvf files/McMojave-circle-black.tar.xz -C $ICONS_PATH

mkdir -p $THEMES_PATH
tar -xvf files/Layan-Dark.tar.xz -C $THEMES_PATH

case $LIGHTDM in
    y)
        case $WEBKIT in
            y)
                git clone https://aur.archlinux.org/lightdm-webkit2-theme-glorious.git /tmp/lightdm-webkit2-theme-glorious
                cd /tmp/lightdm-webkit2-theme-glorious
                makepkg -sri

                cd $SCRIPT_DIR
                sudo tar -xvf files/lightdm-webkit2-theme-glorious-2.0.5.tar.gz -C /usr/share/lightdm-webkit/themes/glorious
                # Set default lightdm greeter to lightdm-webkit2-greeter
                sudo sed -i 's/^#greeter-session.*/greeter-session=lightdm-webkit2-greeter/' /etc/lightdm/lightdm.conf
                # Set default lightdm-webkit2-greeter theme to Glorious
                sudo sed -i 's/^webkit_theme\s*=\s*\(.*\)/webkit_theme = glorious #\1/g' /etc/lightdm/lightdm-webkit2-greeter.conf
                ;;
            n)
                cd $SCRIPT_DIR
                sudo sed -i 's/^#greeter-session.*/greeter-session=lightdm-slick-greeter/' /etc/lightdm/lightdm.conf
                ;;
        esac
        ;;
esac

 
#GTK_THEME=Breeze-Dark
#sudo pacman -S remmina freerdp

echo
echo "### DONE FOR CONFIGURATION ###"
