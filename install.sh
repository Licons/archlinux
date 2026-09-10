#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_PASS="676021"

read -p "Enter your hostname: " HOST_NAME
read -p "Enter your username: " USER_NAME
read -p "Enter your GPU (n/nvidia or i/intel or a/amd or o/others): " GPU
read -p "Set timeout for GRUB: " TIMEOUT_GRUB
read -p "Your DE (kde or cinnamon or hyprland): " DE

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

cd $SCRIPT_DIR
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
        pacman -S --noconfirm \
            xf86-video-intel mesa
        ;;
    a|amd)
        pacman -S --noconfirm \
            xf86-video-amdgpu mesa
        ;;
    *)
        echo "You must be install later."
        ;;
esac

echo
echo
echo "##################################################"
echo "###                INSTALL $DE                 ###"
echo "##################################################"
echo
echo

case $DE in
    kde)
        pacman -S --noconfirm --needed \
            plasma-desktop \
            sddm sddm-kcm \
            dolphin dolphin-plugins spectacle ark gwenview okular \
            konsole kalk kate kalarm kcharselect kdenetwork-filesharing kvantum 7zip

        systemctl enable sddm

        mkdir -p /usr/share/sddm
        7z x sddm.7z -o/usr/share/sddm/ -aoa -bb1

        echo
        echo
        echo "##################################################"
        echo "###          CONFIGURE SHARE                   ###"
        echo "##################################################"
        echo
        echo

        sudo pacman -S --noconfirm --needed samba smbclient
        systemctl enable smb nmb

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

        # Fix AccountsService avatar bug (Arch + KDE)
mkdir -p /etc/systemd/system/accounts-daemon.service.d
tee /etc/systemd/system/accounts-daemon.service.d/override.conf >/dev/null <<'EOF'
[Service]
ProtectSystem=false
EOF

        ;;
    cinnamon)
        pacman -S --noconfirm --needed \
            xorg-server \
            cinnamon \
            lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings lightdm-slick-greeter \
            xed xviewer pix \
            gnome-terminal gnome-screenshot gnome-system-monitor gnome-calculator gnome-calendar \
            nemo-fileroller nemo-terminal nemo-share \
            gufw \
            xdg-user-dirs xdg-user-dirs-gtk \
            blueman

        systemctl enable lightdm
        ;;
    hyprland)
        pacman -S --needed --noconfirm \
            hyprland waybar kitty swaybg swaync rofi \
            hyprpicker grim slurp cliphist thunar qt5-wayland qt6-wayland polkit-gnome \
            udisks2 udiskie gnome-disk-utility \
            sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg libnotify \
            nwg-look \
            ttf-jetbrains-mono-nerd noto-fonts-cjk ttf-font-awesome papirus-icon-theme \
            fastfetch chafa hyprlock brightnessctl wireplumber networkmanager \
            pavucontrol blueman btop python-requests mpd mpc ncmpcpp cava 7zip

        systemctl enable sddm
        systemctl enable mpd

        mkdir -p /usr/share/sddm
        7z x sddm.7z -o/usr/share/sddm/ -aoa -bb1
        ;;
    *)
        echo "Nothing in setup DE."
        ;;
esac

echo
echo "### Install $DE and Apps completed!"

echo
echo
echo "##################################################"
echo "###            INSTALL APPS                    ###"
echo "##################################################"
echo
echo

echo "# FONTS #"
pacman -S --noconfirm --needed \
    ttf-roboto ttf-dejavu ttf-liberation \
    ttf-carlito ttf-material-icons ttf-material-symbols-variable ttf-cascadia-code \
    ttf-jetbrains-mono ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols \
    noto-fonts noto-fonts-cjk noto-fonts-emoji \
    otf-font-awesome ttf-font-awesome

echo
echo "# APPS #"
pacman -S --noconfirm --needed \
    flatpak network-manager-applet \
    vulkan-icd-loader lib32-vulkan-icd-loader \
    pacman-contrib system-config-printer jq \
    pipewire pipewire-audio pipewire-pulse pipewire-alsa wireplumber \
    bluez bluez-utils bluedevil \
    powerdevil power-profiles-daemon \
    ufw ufw-extras \
    fastfetch fish wget curl 7zip \
    fcitx5-im fcitx5-configtool fcitx5-unikey \
    docker docker-compose docker-buildx \
    git-lfs less rclone \
    firefox vlc \
    libreoffice-fresh \
    nodejs npm jdk-openjdk \
    dbeaver postgresql code \
    tela-circle-icon-theme-purple

systemctl enable NetworkManager
systemctl enable systemd-timesyncd
systemctl enable fstrim.timer

systemctl enable bluetooth
systemctl enable ufw
systemctl enable docker

usermod -aG docker $USER_NAME

echo
echo "### Install Apps completed!"

exit
