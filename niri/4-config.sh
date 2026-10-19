#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KVANTUM_PATH=/usr/share/Kvantum
ICONS_PATH=$HOME/.icons
THEMES_PATH=$HOME/.themes

echo
echo
echo "##################################################"
echo "###             CONFIGURE GIT                  ###"
echo "##################################################"
echo
echo

cat <<EOF > ~/.gitconfig
[user]
    name = Qua, Chau Ngoc
    email = quacn@utop.io
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

mkdir -p $ICONS_PATH
tar -xvf ./../files/Layan-white-cursors.tar.xz -C $ICONS_PATH

mkdir -p $THEMES_PATH
tar -xvf ./../files/Layan-Dark.tar.xz -C $THEMES_PATH

sudo mkdir -p $KVANTUM_PATH
sudo tar -xvf ./../files/Layan-Kvantum.tar.xz -C $KVANTUM_PATH

chsh -s /usr/bin/fish "$USER"

read -p "GPU (n/nvidia | on/old-nvidia | i/intel | a/amd | v|virtualbox | o/others): " GPU

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

        # yay -S --noconfirm --needed rustdesk-unattended-wayland

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

reboot
