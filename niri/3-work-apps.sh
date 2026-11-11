#!/usr/bin/env bash
set -euo pipefail

# Arch Linux workstation - WORK APPS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ $EUID -eq 0 ]] && { echo "Run as normal user, not root."; exit 1; }

PACMAN=(sudo pacman -S --needed --noconfirm)

echo "==> [WORK] Installing desktop/work applications"
"${PACMAN[@]}" \
  vulkan-icd-loader lib32-vulkan-icd-loader \
  pacman-contrib system-config-printer jq \
  firefox vlc vlc-plugin-ffmpeg ffmpeg libreoffice-fresh \
  markdownpart meld gitfourchette \
  geany geany-plugins \
  nodejs npm jdk-openjdk \
  postgresql \
  docker docker-compose docker-buildx \
  fuse2 tmux \
  python-openpyxl python-opencv python-docx \
  zram-generator \
  telegram-desktop \
  azure-cli

echo "==> [WORK] Docker"
sudo systemctl enable docker.service
sudo usermod -aG docker "$USER"

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

rm -rf /tmp/greetd-dms-greeter-bin
git clone https://aur.archlinux.org/greetd-dms-greeter-bin.git /tmp/greetd-dms-greeter-bin
cd /tmp/greetd-dms-greeter-bin && makepkg -si --noconfirm
cd $SCRIPT_DIR
sudo dms-greeter enable
