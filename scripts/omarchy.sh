#!/bin/bash

set -e

sudo pacman -S --noconfirm --needed \
    pacman-contrib system-config-printer jq \
    pipewire pipewire-audio pipewire-alsa wireplumber \
    bluez bluez-utils bluedevil \
    powerdevil power-profiles-daemon  \
    ufw ufw-extras \
    fastfetch fish wget curl 7zip \
    fcitx5-im fcitx5-configtool fcitx5-unikey \
    ttf-roboto ttf-dejavu ttf-liberation ttf-jetbrains-mono \
    noto-fonts noto-fonts-cjk noto-fonts-emoji \
    docker docker-compose docker-buildx \
    git-lfs less rclone \
    firefox vlc \
    nodejs npm jdk-openjdk \
    dbeaver postgresql code

sudo chsh -s /usr/bin/fish $USER

sudo systemctl enable ufw
sudo systemctl enable fstrim.timer
sudo usermod -aG docker $USER

sudo snapper -c root set-config "TIMELINE_CREATE=no"

mkdir -p ~/.config
7z x config.7z -o"$HOME/.config/" -aoa -bb1

fcitx5-configtool | true

sudo pacman -S --noconfirm flatpak gnome-software
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.github.IsmaelMartinez.teams_for_linux
mkdir -p ~/.config/autostart
cat <<EOF > ~/.config/autostart/teams.desktop
[Desktop Entry]
Type=Application
Name=Teams for Linux
Exec=flatpak run com.github.IsmaelMartinez.teams_for_linux
X-GNOME-Autostart-enabled=true
EOF