#!/bin/bash

set -e

echo "========================================="
echo "      Waydroid Auto Installer (Arch)"
echo "========================================="


echo
echo "[1/5] Cài Waydroid và dependencies..."
yay -S --needed --noconfirm \
    waydroid \
    waydroid-script-git

echo
echo "[2/5] Khởi tạo Waydroid (GAPPS)..."
sudo waydroid init -s GAPPS

echo
echo "[3/5] Cài ARM Translation Layer..."

# libhoudini / libndk
sudo waydroid-extras install libhoudini

echo
echo "[4/5] Configuration..."
sudo ufw allow in on waydroid0
sudo ufw allow out on waydroid0
sudo ufw route allow in on waydroid0 out on wlan0
sudo ufw route allow in on waydroid0 out on enp3s0
sudo sysctl -w net.ipv4.ip_forward=1
sudo tee /etc/sysctl.d/99-waydroid.conf  >/dev/null <<'EOF'
net.ipv4.ip_forward=1
EOF


echo
echo "[5/5] Enable container..."
sudo systemctl enable --now waydroid-container

waydroid session start &
sleep 5

waydroid prop set persist.waydroid.width 1280
waydroid prop set persist.waydroid.height 720

sudo systemctl restart waydroid-container
