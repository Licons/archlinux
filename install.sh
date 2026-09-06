#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_PASS="676021"
NVIDIA="580.95.05-1"

read -p "Enter your hostname: " HOST_NAME
read -p "Enter your username: " USER_NAME
read -p "Enter your GPU (n/nvidia or i/intel or amd or o/others): " GPU
read -p "Set timeout for GRUB: " TIMEOUT_GRUB
read -p "Your DE (KDE or Cinnamon or Hyprland): " DE

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

cd $SCRIPT_DIR

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

cp -fv $SCRIPT_DIR/pictures/background.jpg /usr/share/grub/themes/tela/background.jpg
chmod -x /etc/grub.d/30_uefi-firmware
grub-mkconfig -o /boot/grub/grub.cfg

echo
echo "### Install ArchLinux completed!"

pacman -Syu --noconfirm

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
            nvidia-utils opencl-nvidia \
            lib32-nvidia-utils lib32-opencl-nvidia
        ;;
    i|intel)
        pacman -S --noconfirm mesa xf86-video-intel
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

pacman -S --noconfirm vulkan-icd-loader lib32-vulkan-icd-loader

echo
echo
echo "##################################################"
echo "###                INSTALL $DE                 ###"
echo "##################################################"
echo
echo

case $DE in
    KDE)
        pacman -S --noconfirm \
            plasma-meta \
            plasma-x11-session \
            sddm sddm-kcm \
            dolphin dolphin-plugins spectacle ark gwenview okular \
            konsole kalk kate kalarm kcharselect kdenetwork-filesharing \
            flatpak kvantum-qt5
        systemctl enable sddm
        ;;
    Cinnamon)
        pacman -S --noconfirm \
            cinnamon \
            lightdm lightdm-gtk-greeter lightdm-slick-greeter \
            gnome-terminal gnome-screenshot gnome-system-monitor gnome-calculator \
            nemo-fileroller nemo-terminal \
            gufw \
            xdg-user-dirs xdg-user-dirs-gtk
        systemctl enable lightdm
        ;;
    Hyprland)
        git clone https://github.com/JaKooLit/Arch-Hyprland.git /tmp/Arch-Hyprland
        cd /tmp/Arch-Hyprland
        bash ./install.sh
        ;;
    *)
        echo "Nothing in setup DE."
        ;;
esac

echo
echo
echo "##################################################"
echo "###            INSTALL APPS                    ###"
echo "##################################################"
echo
echo

pacman -S --noconfirm \
    pacman-contrib system-config-printer jq \
    pipewire pipewire-audio pipewire-alsa wireplumber \
    bluez bluez-utils bluedevil \
    powerdevil power-profiles-daemon \
    ufw ufw-extras \
    fastfetch fish wget curl 7zip \
    fcitx5-im fcitx5-configtool fcitx5-unikey \
    ttf-roboto ttf-dejavu ttf-liberation ttf-jetbrains-mono \
    noto-fonts noto-fonts-cjk noto-fonts-emoji \
    docker docker-compose docker-buildx \
    git-lfs less rclone \
    firefox vlc \
    libreoffice-fresh \
    nodejs npm jdk-openjdk \
    dbeaver postgresql code \
    tela-circle-icon-theme-all

systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable ufw
systemctl enable systemd-timesyncd
systemctl enable docker
systemctl enable fstrim.timer

usermod -aG docker $USER_NAME

cd $SCRIPT_DIR

echo
echo
echo "##################################################"
echo "###          CONFIGURE SHARE                   ###"
echo "##################################################"
echo
echo

mkdir -p /usr/share/sddm
7z x sddm.7z -o/usr/share/sddm/ -aoa -bb1

echo
echo
echo "##################################################"
echo "###          CONFIGURE SHARE                   ###"
echo "##################################################"
echo
echo

mkdir -p /var/lib/samba
mkdir -p /var/lib/samba/usershares
groupadd -r sambashare
chown root:sambashare /var/lib/samba/usershares
chmod 1770 /var/lib/samba/usershares
usermod -aG sambashare $USER_NAME

mkdir -p /etc/samba
tee /etc/samba/smb.conf > /dev/null <<EOF
[global]
   workgroup = WORKGROUP

   usershare path = /var/lib/samba/usershares
   usershare max shares = 100
   usershare allow guests = yes
   usershare owner only = yes
EOF

systemctl enable smb nmb

# Fix AccountsService avatar bug (Arch + Plasma)
mkdir -p /etc/systemd/system/accounts-daemon.service.d
tee /etc/systemd/system/accounts-daemon.service.d/override.conf >/dev/null <<'EOF'
[Service]
ProtectSystem=false
EOF

echo
echo "### Install KDE and Apps completed!"

exit
