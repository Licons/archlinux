#!/bin/bash

set -e

# cleanup_arch.sh - Dọn dẹp hệ thống Arch Linux

echo "🚀 Bắt đầu dọn dẹp hệ thống Arch Linux..."

# Kiểm tra quyền root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Vui lòng chạy với quyền sudo hoặc root."
   exit 1
fi

# 1. Xoá cache gói pacman (giữ lại 1 bản mới nhất)
echo "🧹 Xoá cache pacman..."
paccache -rk1

# 2. Gỡ gói mồ côi (orphans)
echo "🧺 Gỡ các gói mồ côi không còn dùng..."
# pacman -Qtdq thoát mã 1 khi không có gói mồ côi -> set -e sẽ dừng script.
orphans=$(pacman -Qtdq || true)
if [[ -n "$orphans" ]]; then
    pacman -Rns --noconfirm $orphans
else
    echo "✅ Không có gói mồ côi."
fi

# 3. Xoá log hệ thống cũ (chỉ giữ lại log 7 ngày)
echo "🗑 Xoá log cũ từ journalctl..."
journalctl --vacuum-time=7d

# Chạy qua sudo thì ~ là /root: lấy home của user đã gọi sudo.
USER_HOME=$(getent passwd "${SUDO_USER:-root}" | cut -d: -f6)

# 4. Xoá cache AUR (yay không chạy dưới root)
if [[ -n ${SUDO_USER:-} ]] && command -v yay &> /dev/null; then
    echo "📦 Dọn cache yay..."
    sudo -u "$SUDO_USER" yay -Sc --noconfirm
fi

# 5. Xoá cache người dùng
echo "🧽 Dọn cache người dùng tại $USER_HOME/.cache..."
rm -rf "${USER_HOME:?}"/.cache/*

# 6. Thông báo hoàn tất
echo "✅ Dọn dẹp hoàn tất!"
