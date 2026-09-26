#!/bin/bash

set -e

echo "=== Updating system ==="
sudo pacman -Syu --noconfirm

echo "=== Installing virtualization packages ==="
sudo pacman -S --needed --noconfirm \
    qemu-full \
    virt-manager \
    dnsmasq \
    android-tools

echo "=== Installing Genymotion from AUR ==="
yay -S --noconfirm genymotion

echo "=== Configuring KVM permissions ==="
sudo usermod -aG kvm "$USER"

# wget -P ~/Downloads https://release-assets.githubusercontent.com/github-production-release-asset/597282645/bc2d4788-a541-4163-9bc2-be1f3ba4c4df?sp=r&sv=2018-11-09&sr=b&spr=https&se=2026-07-03T03%3A29%3A51Z&rscd=attachment%3B+filename%3Dsystem.zip&rsct=application%2Foctet-stream&skoid=96c2d410-5711-43a1-aedd-ab1947aa7ab0&sktid=398a6654-997b-47e9-b12b-9515b896b4de&skt=2026-07-03T02%3A29%3A05Z&ske=2026-07-03T03%3A29%3A51Z&sks=b&skv=2018-11-09&sig=wUl4JoXXlCXTIypWVi4Yv0OpLsFDdMXnX85%2BWlUBvlM%3D&jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmVsZWFzZS1hc3NldHMuZ2l0aHVidXNlcmNvbnRlbnQuY29tIiwia2V5Ijoia2V5MSIsImV4cCI6MTc4MzA1MDU0MSwibmJmIjoxNzgzMDQ2OTQxLCJwYXRoIjoicmVsZWFzZWFzc2V0cHJvZHVjdGlvbi5ibG9iLmNvcmUud2luZG93cy5uZXQifQ.FcZS1NADmSSnrpjeMRiNBIXKQB2WKR976urRa5BYI68&response-content-disposition=attachment%3B%20filename%3Dsystem.zip&response-content-type=application%2Foctet-stream

# adb shell
#
# su
#
# mount -o rw,remount /
#
# echo 'ro.product.cpu.abilist=x86_64,x86,arm64-v8a,armeabi-v7a,armeabi
# ro.product.cpu.abilist32=x86,armeabi-v7a,armeabi
# ro.product.cpu.abilist64=x86_64,arm64-v8a
# ro.vendor.product.cpu.abilist=x86_64,x86,arm64-v8a,armeabi-v7a,armeabi
# ro.vendor.product.cpu.abilist32=x86,armeabi-v7a,armeabi
# ro.vendor.product.cpu.abilist64=x86_64,arm64-v8a
# ro.odm.product.cpu.abilist=x86_64,x86,arm64-v8a,armeabi-v7a,armeabi
# ro.odm.product.cpu.abilist32=x86,armeabi-v7a,armeabi
# ro.odm.product.cpu.abilist64=x86_64,arm64-v8a
# ro.dalvik.vm.native.bridge=libhoudini.so
# ro.enable.native.bridge.exec=1
# ro.enable.native.bridge.exec64=1
# ro.dalvik.vm.isa.arm=x86
# ro.dalvik.vm.isa.arm64=x86_64
# ro.zygote=zygote64_32' | tee -a /system/build.prop >> /system/vendor/build.prop
