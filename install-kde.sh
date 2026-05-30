#!/bin/bash
set -e

read -p "Enter your hostname: " hostname
read -p "Enter your username: " username
read -p "Enter your GPU (n/nvidia or i/intel or amd): " GPU
read -p "Set timeout for GRUB: " timeoutgrub

echo
echo
echo "##################################################"
echo "###              SETUP TIMEZONE                ###"
echo "##################################################"
echo
echo

ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
timedatectl set-timezone Asia/Ho_Chi_Minh
timedatectl set-ntp true

echo
echo
echo "##################################################"
echo "###             CONFIGURE LOCALE               ###"
echo "##################################################"
echo
echo

if ! grep -q "en_US.UTF-8 UTF-8" /etc/locale.gen; then
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
fi
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo
echo
echo "##################################################"
echo "###           CONFIGURE HOSTNAME               ###"
echo "##################################################"
echo
echo

echo "$hostname" > /etc/hostname
if ! grep -q "127.0.0.1 $hostname" /etc/hosts; then
    echo "127.0.0.1 $hostname" >> /etc/hosts
fi

echo
echo
echo "##################################################"
echo "###           PASSWORD FOR ROOT                ###"
echo "##################################################"
echo
echo

passwd

echo
echo
echo "##################################################"
echo "###           PASSWORD FOR USER                ###"
echo "##################################################"
echo
echo

useradd -mG wheel "$username"
echo "==> Create and setup password for user: $username"
passwd "$username"

echo
echo
echo "##################################################"
echo "###              SETUP WHEEL                   ###"
echo "##################################################"
echo
echo

EDITOR=nano visudo

echo
echo
echo "##################################################"
echo "###           CONFIGURE PACMAN                 ###"
echo "##################################################"
echo
echo

sed -i '/^\#\[multilib\]/{n;s/^#Include = \/etc\/pacman\.d\/mirrorlist/Include = \/etc\/pacman\.d\/mirrorlist/;s/^#//}' /etc/pacman.conf
sed -i 's/^#\[multilib\]/\[multilib\]/' /etc/pacman.conf

echo
echo
echo "##################################################"
echo "###             UPDATE SYSTEM                  ###"
echo "##################################################"
echo
echo

pacman -Syu --noconfirm

echo
echo
echo "##################################################"
echo "###         CONFIGURE MKINITCPIO               ###"
echo "##################################################"
echo
echo

echo "KEYMAP=us" > /etc/vconsole.conf
sed -i \
    -e "s|^PRESETS=('default' 'fallback')|PRESETS=('default')|" \
    -e 's|^fallback_image=|#fallback_image=|' \
    -e 's|^fallback_options=|#fallback_options=|' \
    /etc/mkinitcpio.d/linux.preset

rm -f /boot/initramfs-linux-fallback.img
mkinitcpio -P

echo
echo
echo "##################################################"
echo "###            CONFIGURE GRUB                  ###"
echo "##################################################"
echo
echo

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB

echo
echo "==> Install theme for GRUB"
cd /tmp
git clone https://github.com/vinceliuice/grub2-themes.git
cd grub2-themes
./install.sh -t tela

echo
echo "==> Update GRUB"
cd /
sed -i \
    -e "s|^GRUB_DEFAULT=.*|GRUB_DEFAULT=saved|" \
    -e "s|^GRUB_TIMEOUT=.*|GRUB_TIMEOUT=$timeoutgrub|" \
    -e "s|^#GRUB_DISABLE_RECOVERY=.*|GRUB_DISABLE_RECOVERY=true|" \
    -e "s|^#GRUB_SAVEDEFAULT=.*|GRUB_SAVEDEFAULT=true|" \
    -e "s|^#GRUB_DISABLE_SUBMENU=.*|GRUB_DISABLE_SUBMENU=y|" \
    -e "s|^#GRUB_DISABLE_OS_PROBER=.*|GRUB_DISABLE_OS_PROBER=false|" \
    /etc/default/grub

cp -fv /tmp/arch-kde/pictures/background.jpg /usr/share/grub/themes/tela/background.jpg
chmod -x /etc/grub.d/30_uefi-firmware
grub-mkconfig -o /boot/grub/grub.cfg

echo
echo "### Install ArchLinux completed!"

echo
echo
echo "##################################################"
echo "###               GPU DRIVER                   ###"
echo "##################################################"
echo
echo

case $GPU in
    n|nvidia)
        pacman -S --noconfirm \
            nvidia-dkms nvidia-settings \
            nvidia-utils lib32-nvidia-utils \
            vulkan-icd-loader lib32-vulkan-icd-loader
        ;;
    i|intel)
        pacman -S --noconfirm \
            mesa xf86-video-intel \
            vulkan-icd-loader lib32-vulkan-icd-loader
        ;;
    amd)
        pacman -S --noconfirm \
            mesa vulkan-radeon \
            libva-mesa-driver mesa-vdpau
        ;;
    *)
        echo "You must be install later."
        ;;
esac

echo
echo
echo "##################################################"
echo "###          INSTALL KDE & APPS                ###"
echo "##################################################"
echo
echo

pacman -S --noconfirm \
    plasma-meta \
    plasma-x11-session \
    sddm sddm-kcm \
    konsole dolphin dolphin-plugins spectacle ark gwenview kalk kate jq okular \
    flatpak pacman-contrib kvantum-qt5 system-config-printer \
    pipewire pipewire-audio pipewire-alsa pipewire-jack wireplumber \
    bluez bluez-utils bluedevil \
    powerdevil power-profiles-daemon \
    ufw ufw-extras \
    fastfetch fish wget curl unrar \
    fcitx5-im fcitx5-configtool fcitx5-unikey \
    ttf-roboto ttf-dejavu ttf-liberation ttf-jetbrains-mono \
    noto-fonts noto-fonts-cjk noto-fonts-emoji \
    docker docker-compose

systemctl enable sddm
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable ufw
systemctl enable systemd-timesyncd
systemctl enable docker
systemctl enable fstrim.timer

usermod -aG docker $username

echo
echo "### Install KDE and Apps completed!"

exit
