#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIC_PATH=$HOME/Pictures/Wallpapers
ICONS_PATH=$HOME/.icons
THEMES_PATH=$HOME/.themes
KVANTUM_PATH=/usr/share/Kvantum

# Arch Linux workstation - WORK APPS

[[ $EUID -eq 0 ]] && { echo "Run as normal user, not root."; exit 1; }

PACMAN=(sudo pacman -S --needed --noconfirm)

echo "==> [WORK] Installing desktop/work applications"
"${PACMAN[@]}" \
  vulkan-icd-loader lib32-vulkan-icd-loader \
  pacman-contrib system-config-printer jq \
  firefox vlc libreoffice-fresh \
  kate markdownpart meld gitfourchette \
  nodejs npm jdk-openjdk \
  dbeaver postgresql \
  docker docker-compose docker-buildx \
  fuse2 tmux \
  python-openpyxl python-docx \
  zram-generator

# window-rule {
#     match app-id=r#"^firefox$"#
#     match app-id=r#"^google-chrome$"#
#     exclude title="^Picture[- ]in[- ][Pp]icture$"
#     open-maximized-to-edges true
# }

echo "==> [WORK] Docker"
sudo systemctl enable docker.service
sudo usermod -aG docker "$USER"

echo "==> [WORK] Git LFS"
git lfs install --skip-repo

sudo tee /etc/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
EOF

sudo tee /etc/sysctl.d/99-memory.conf <<'EOF'
vm.swappiness=150
vm.vfs_cache_pressure=100
EOF

sudo systemctl daemon-reload
sudo systemctl start /dev/zram0

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

mkdir -p $PIC_PATH
mkdir -p $PIC_PATH/../Logo
cp $SCRIPT_DIR/../pictures/train.png $PIC_PATH
cp $SCRIPT_DIR/../pictures/avatar.jpg $PIC_PATH/../Logo

mkdir -p $ICONS_PATH
tar -xvf $SCRIPT_DIR/../files/Layan-white-cursors.tar.xz -C $ICONS_PATH
tar -xvf $SCRIPT_DIR/../files/Future-cursors.tar.gz -C $ICONS_PATH
tar -xvf $SCRIPT_DIR/../files/McMojave-circle-black.tar.xz -C $ICONS_PATH

mkdir -p $THEMES_PATH
tar -xvf $SCRIPT_DIR/../files/Layan-Dark.tar.xz -C $THEMES_PATH

sudo mkdir -p $KVANTUM_PATH
sudo 7z x $SCRIPT_DIR/../files/Kvantum.7z -o"$KVANTUM_PATH" -aoa -bb1

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

        # yay -S --noconfirm rustdesk-unattended-wayland

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
