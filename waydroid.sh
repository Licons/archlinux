#!/bin/bash

set -e

echo
echo
echo "##################################################"
echo "###           INSTALL WAYDROID                 ###"
echo "##################################################"
echo
echo

echo "=== Xóa waydroid cũ ==="
# sudo systemctl stop waydroid-container
# sudo pacman -Rns waydroid --noconfirm
sudo rm -rf /var/lib/waydroid
sudo rm -rf ~/.local/share/waydroid

echo "=== Cập nhật hệ thống ==="
yay -Syu --noconfirm

echo "=== Cài đặt waydroid ==="
yay -S --noconfirm --needed \
    waydroid \
    waydroid-script-git

echo "=== Init waydroid ==="
sudo waydroid init -s GAPPS
sudo waydroid-extras install libhoudini
sudo waydroid-extras install libndk
sudo systemctl enable --now waydroid-container

echo "=== Allow UFW ==="
sudo ufw allow in on waydroid0
sudo ufw allow out on waydroid0

echo "=== Setting ==="
sudo sed -i \
    -e "s|^DEFAULT_FORWARD_POLICY=.*|DEFAULT_FORWARD_POLICY="ACCEPT"|" \
    /etc/default/ufw
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-waydroid.conf
# sudo sysctl --system

waydroid session start
waydroid prop set persist.waydroid.multi_windows true
waydroid show-full-ui


echo
echo "### INSTALLED APPS ###"

exit
