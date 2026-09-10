#!/bin/bash

set -e

sudo mkdir -p /mnt/win_efi
sudo mount /dev/nvme0n1p1 /mnt/win_efi
sudo cp -r /mnt/win_efi/EFI/Microsoft /boot/EFI/
sudo umount /mnt/win_efi
ls /boot/EFI/Microsoft/Boot/bootmgfw.efi
cat <<EOF >> /boot/limine.conf
/Windows
    comment: Boot Windows
    protocol: efi
    path: boot():/EFI/Microsoft/Boot/bootmgfw.efi
EOF
find /boot/EFI/ -iname "bootmgfw.efi"
reboot