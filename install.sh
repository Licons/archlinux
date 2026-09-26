#!/bin/bash
set -e

ROOT_PASS="676021"

read -p "Your hostname: " HOST_NAME
read -p "Your username: " USER_NAME
read -p "Timeout for GRUB: " TIMEOUT_GRUB

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

echo "$HOST_NAME" > /etc/hostname
if ! grep -q "127.0.0.1 $HOST_NAME" /etc/hosts; then
    echo "127.0.0.1 $HOST_NAME" >> /etc/hosts
fi

echo
echo
echo "##################################################"
echo "###           PASSWORD FOR ROOT                ###"
echo "##################################################"
echo
echo

echo "root:$ROOT_PASS" | chpasswd

echo
echo
echo "##################################################"
echo "###           PASSWORD FOR USER                ###"
echo "##################################################"
echo
echo

echo "==> Create and setup password for user: $USER_NAME"
useradd -mG wheel "$USER_NAME"
passwd $USER_NAME

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
git clone https://github.com/vinceliuice/grub2-themes.git
cd grub2-themes
./install.sh -t tela
cd ..

echo
echo "==> Update GRUB"
cd /
sed -i \
    -e "s|^GRUB_DEFAULT=.*|GRUB_DEFAULT=saved|" \
    -e "s|^GRUB_TIMEOUT=.*|GRUB_TIMEOUT=$TIMEOUT_GRUB|" \
    -e "s|^#GRUB_DISABLE_RECOVERY=.*|GRUB_DISABLE_RECOVERY=true|" \
    -e "s|^#GRUB_SAVEDEFAULT=.*|GRUB_SAVEDEFAULT=true|" \
    -e "s|^#GRUB_DISABLE_SUBMENU=.*|GRUB_DISABLE_SUBMENU=y|" \
    -e "s|^#GRUB_DISABLE_OS_PROBER=.*|GRUB_DISABLE_OS_PROBER=false|" \
    /etc/default/grub

cp -fv ./pictures/background.jpg /usr/share/grub/themes/tela/background.jpg
chmod -x /etc/grub.d/30_uefi-firmware
chmod -x /etc/grub.d/31_efi_bootnext
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager
systemctl enable systemd-timesyncd
systemctl enable fstrim.timer

echo
echo "### Install ArchLinux completed!"
