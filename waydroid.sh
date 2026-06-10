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
sudo rm -rf ~/waydroid ~/.share/waydroid ~/.local/share/applications/*aydroid* ~/.local/share/waydroid

echo "=== Cập nhật hệ thống ==="
yay -Syu --noconfirm

echo "=== Cài đặt waydroid ==="
yay -S --noconfirm --needed \
    waydroid \
    waydroid-script-git

echo "=== Init waydroid ==="
sudo waydroid init -s GAPPS
sudo waydroid-extras install libhoudini
# sudo waydroid-extras install libndk
sudo systemctl enable --now waydroid-container

echo "=== Allow UFW ==="
sudo ufw allow in on waydroid0
sudo ufw allow out on waydroid0
sudo ufw allow 67
sudo ufw allow 53
sudo ufw default allow FORWARD


echo "=== Setting ==="
# sudo sed -i \
#     -e "s|^DEFAULT_FORWARD_POLICY=.*|DEFAULT_FORWARD_POLICY="ACCEPT"|" \
#     /etc/default/ufw
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-waydroid.conf
# sudo sysctl --system

waydroid session start

waydroid prop set persist.waydroid.multi_windows true
waydroid prop set persist.waydroid.width 576
waydroid prop set persist.waydroid.height 1024
waydroid prop set persist.waydroid.udev true
waydroid prop set persist.waydroid.uevent true

waydroid session stop
waydroid session start

echo
echo "### INSTALLED APPS ###"

# Make sure that you have already run:
#
# # waydroid init
#
# (see #Installation section for more information)
#
# Then, add the following:
#
# /var/lib/waydroid/waydroid.cfg
#
# [properties]
# ro.hardware.gralloc=default
# ro.hardware.egl=swiftshader
#
# Then run
#
# # waydroid upgrade --offline
#
# to apply configurations to actual props.
#
# Finally, run restart the waydroid-container.service.

exit
