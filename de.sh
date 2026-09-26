#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIC_PATH=$HOME/Pictures/Wallpapers
KVANTUM_PATH=$HOME/.config/Kvantum
ICONS_PATH=$HOME/.icons
THEMES_PATH=$HOME/.themes
SDDM_PATH=/usr/share/sddm

read -p "GPU (n/nvidia | on/old-nvidia | i/intel | a/amd | v|virtualbox | o/others): " GPU
read -p "DE (k/kde | c/cinnamon | o/other): " DE
read -p "GIT username: " GIT_USER
read -p "GIT email: " GIT_EMAIL

sudo pacman -Syu --noconfirm --needed

echo
echo
echo "##################################################"
echo "###               GPU DRIVER                   ###"
echo "##################################################"
echo
echo

case $GPU in
    n|nvidia)
        sudo pacman -S --noconfirm --needed \
            nvidia-dkms nvidia-settings \
            nvidia-utils opencl-nvidia \
            lib32-nvidia-utils lib32-opencl-nvidia
        ;;
    on|old-nvidia)
        echo
        echo
        echo "##################################################"
        echo "###                SETUP YAY                   ###"
        echo "##################################################"
        echo
        echo

        git clone https://aur.archlinux.org/yay /tmp/yay
        cd /tmp/yay && makepkg -si --noconfirm
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
    i|intel)
        sudo pacman -S --noconfirm --needed xf86-video-intel mesa
        ;;
    a|amd)
        sudo pacman -S --noconfirm --needed xf86-video-amdgpu mesa
        ;;
    v|virtualbox)
        sudo pacman -S --noconfirm --needed virtualbox-guest-utils
        sudo systemctl enable vboxservice.service
        ;;
    *)
        echo "Nothing for you."
        ;;
esac

echo
echo
echo "##################################################"
echo "###                INSTALL DE                  ###"
echo "##################################################"
echo
echo

cd $SCRIPT_DIR
case $DE in
    k|kde)
        sudo pacman -S --noconfirm --needed \
            plasma-desktop \
            sddm sddm-kcm \
            dolphin dolphin-plugins spectacle ark gwenview okular \
            konsole kalk kate kalarm kcharselect kdenetwork-filesharing kvantum
        sudo systemctl enable sddm

        # Fix AccountsService avatar bug (Arch + KDE)
        sudo mkdir -p /etc/systemd/system/accounts-daemon.service.d
        sudo tee /etc/systemd/system/accounts-daemon.service.d/override.conf >/dev/null <<'EOF'
[Service]
ProtectSystem=false
EOF

        sudo mkdir -p $SDDM_PATH
        sudo 7z x files/Kvantum.7z -o"$SDDM_PATH" -aoa -bb1
        ;;

    c|cinnamon)
        sudo pacman -S --noconfirm --needed \
            xorg-server xorg-xwayland \
            cinnamon udisks2 gvfs gvfs-mtp libmtp \
            lightdm lightdm-gtk-greeter lightdm-slick-greeter \
            gnome-terminal gnome-console gnome-screenshot gnome-system-monitor gnome-calculator gnome-calendar gnome-characters gnome-text-editor gnome-photos \
            nemo nemo-fileroller nemo-terminal nemo-share \
            ufw ufw-extras gufw blueman \
            xdg-user-dirs xdg-user-dirs-gtk \
            kate konsole meld kvantum
        sudo systemctl enable lightdm

        cd $SCRIPT_DIR
        sudo cp ./pictures/train.png /usr/share/backgrounds/lockout.png
        sudo find /usr/share/backgrounds -type d -exec chmod 755 {} +

        sudo mkdir -p /etc/lightdm
        sudo cp files/lightdm.conf /etc/lightdm/lightdm.conf
sudo tee /etc/lightdm/slick-greeter.conf >/dev/null <<'EOF'
[Greeter]
background=/usr/share/backgrounds/lockout.png
theme-name=Mojave-Dark
icon-theme-name=Tela-circle-red-dark
content-align=center
cursor-theme-name=Breeze_Light
clock-format=%H:%M:%S
draw-user-backgrounds=false
EOF

        git clone https://aur.archlinux.org/lightdm-settings.git /tmp/lightdm-settings
        cd /tmp/lightdm-settings && makepkg -si --noconfirm
        cd $SCRIPT_DIR
        ;;

    *)
        echo "Nothing for DE."
        ;;
esac


echo
echo
echo "##################################################"
echo "###            INSTALL APPS                    ###"
echo "##################################################"
echo
echo

sudo pacman -S --noconfirm --needed \
    ttf-roboto ttf-dejavu ttf-liberation \
    ttf-jetbrains-mono ttf-nerd-fonts-symbols \
    noto-fonts noto-fonts-cjk noto-fonts-emoji \
    otf-font-awesome woff2-font-awesome \
    flatpak network-manager-applet \
    vulkan-icd-loader lib32-vulkan-icd-loader \
    pacman-contrib system-config-printer jq \
    pipewire pipewire-audio pipewire-pulse pipewire-alsa wireplumber \
    bluez bluez-utils bluedevil \
    powerdevil power-profiles-daemon \
    ufw ufw-extras \
    fastfetch fish wget curl 7zip \
    fcitx5-im fcitx5-configtool fcitx5-unikey \
    docker docker-compose docker-buildx \
    git-lfs less rclone \
    firefox vlc \
    libreoffice-fresh \
    nodejs npm jdk-openjdk \
    dbeaver postgresql code \
    ghostwriter gitfourchette fuse2 tmux \
    python-openpyxl python-opencv python-docx \
    tela-circle-icon-theme-all

sudo systemctl enable bluetooth
sudo systemctl enable ufw
sudo systemctl enable docker

sudo usermod -aG docker $USER

echo
echo "### Install Apps completed!"

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
set -gx PATH /usr/bin \$HOME/.dotnet/tools \$HOME/.local/bin
set -Ux SSL_CERT_DIR "\$HOME/.aspnet/dev-certs/trust:/etc/ssl/certs"
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
https://Loyalstar:@dev.azure.com
https://licons:@github.com
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
sudo ufw enable

echo
echo
echo "##################################################"
echo "###          CONFIGURE LAYAN                     ###"
echo "##################################################"
echo
echo

git clone https://github.com/vinceliuice/Layan-kde /tmp/layan
cd /tmp/layan
bash install.sh

echo
echo
echo "##################################################"
echo "###          COPY  THEMES                      ###"
echo "##################################################"
echo
echo

cd $SCRIPT_DIR

mkdir -p $PIC_PATH
mkdir -p $PIC_PATH/Logo
cp pictures/train.png $PIC_PATH
cp pictures/avatar.jpg $PIC_PATH/../Logo

mkdir -p $KVANTUM_PATH
7z x files/Kvantum.7z -o"$KVANTUM_PATH" -aoa -bb1

mkdir -p $ICONS_PATH
tar -xvf files/Layan-white-cursors.tar.xz -C $ICONS_PATH
tar -xvf files/Future-cursors.tar.gz -C $ICONS_PATH
tar -xvf files/McMojave-circle-black.tar.xz -C $ICONS_PATH

mkdir -p $THEMES_PATH
tar -xvf files/Layan-Dark.tar.xz -C $THEMES_PATH

#GTK_THEME=Breeze-Dark

chsh -s /usr/bin/fish $USER
