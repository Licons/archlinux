#!/bin/bash

set -e

echo
echo
echo "##################################################"
echo "###               INSTALL APPS                 ###"
echo "##################################################"
echo
echo

echo "=== Cập nhật hệ thống ==="
yay -Syu --noconfirm

echo "=== Cài đặt wine-staging và winetricks ==="
echo "=== Cài DXVK và VKD3D-Proton ==="
yay -S --noconfirm --needed \
    wine-staging winetricks wine-mono wine-gecko \
    dxvk-bin \
    vkd3d lib32-vkd3d \
    vkd3d-proton lib32-vkd3d-proton \
    mangohud

winetricks corefonts vcrun2019 d3dx9 d3dcompiler_43 d3dcompiler_47 dotnet48

echo
echo "### INSTALLED APPS ###"

exit
