#!/bin/bash

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
orphans=$(pacman -Qtdq)
if [[ -n "$orphans" ]]; then
    pacman -Rns --noconfirm $orphans
else
    echo "✅ Không có gói mồ côi."
fi

# 3. Xoá log hệ thống cũ (chỉ giữ lại log 7 ngày)
echo "🗑 Xoá log cũ từ journalctl..."
journalctl --vacuum-time=7d

# 4. Xoá cache AUR (yay)
if command -v yay &> /dev/null; then
    echo "📦 Dọn cache yay..."
    yay -Sc --noconfirm
fi

# 5. Xoá cache người dùng
echo "🧽 Dọn cache người dùng tại ~/.cache..."
rm -rf ~/.cache/*

# 6. Thông báo hoàn tất
echo "✅ Dọn dẹp hoàn tất!"
