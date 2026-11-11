#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KVANTUM_PATH=/usr/share/Kvantum
ICONS_PATH=$HOME/.icons
THEMES_PATH=$HOME/.themes

sudo tar -xzf "$SCRIPT_DIR/../files/zrok_1.1.4_linux_amd64.tar.gz" -C /usr/local/bin zrok
sudo chmod +x /usr/local/bin/zrok
    
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

# Không ghi đè: file có thể đã chứa token thật.
[[ -e ~/.git-credentials ]] || cat <<EOF > ~/.git-credentials
https://Loyalstar:@dev.azure.com
https://licons:@github.com
EOF

mkdir -p $ICONS_PATH
tar -xvf "$SCRIPT_DIR/../files/Layan-white-cursors.tar.xz" -C $ICONS_PATH

mkdir -p $THEMES_PATH
tar -xvf "$SCRIPT_DIR/../files/Layan-Dark.tar.xz" -C $THEMES_PATH

sudo mkdir -p $KVANTUM_PATH
sudo tar -xvf "$SCRIPT_DIR/../files/Layan-Kvantum.tar.xz" -C $KVANTUM_PATH

chsh -s /usr/bin/fish "$USER"

read -p "GPU (n/nvidia | on/old-nvidia | i/intel | a/amd | v|virtualbox | o/others): " GPU

case $GPU in
    n|nvidia)
        # nvidia-dkms đã bị bỏ khỏi repo; bản open chỉ hỗ trợ Turing (GTX 16xx/RTX 20) trở lên.
        sudo pacman -S --noconfirm --needed \
            nvidia-open-dkms nvidia-settings \
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

        rm -rf /tmp/yay
        git clone https://aur.archlinux.org/yay /tmp/yay
        cd /tmp/yay && makepkg -si --noconfirm
        cd $SCRIPT_DIR

        #~ yay -S --noconfirm --needed rustdesk-unattended-wayland
        #~ git clone https://aur.archlinux.org/rustdesk-unattended-wayland.git /tmp/rustdesk && cd /tmp/rustdesk && makepkg -si --noconfirm
        #~ git clone https://aur.archlinux.org/dbx-bin.git /tmp/dbx && /tmp/dbx && makepkg -si --noconfirm

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
            lib32-nvidia-580xx-utils lib32-opencl-nvidia-580xx
        ;;
    i|intel)
        # niri chỉ chạy Wayland: xf86-video-* là driver X11, không dùng tới.
        sudo pacman -S --noconfirm --needed mesa vulkan-intel
        ;;
    a|amd)
        sudo pacman -S --noconfirm --needed mesa vulkan-radeon
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
