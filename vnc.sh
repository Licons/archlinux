#!/bin/bash
set -e

sudo pacman -S --noconfirm --needed x11vnc

mkdir -p ~/.vnc
x11vnc -storepasswd ~/.vnc/passwd

sudo tee /etc/systemd/system/x11vnc.service >/dev/null <<EOF
[Unit]
Description=x11vnc VNC Server
After=display-manager.service network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/bin/x11vnc \
    -display :0 \
    -auth guess \
    -forever \
    -noxdamage \
    -repeat \
    -rfbauth $HOME/.vnc/passwd \
    -rfbport 5900 \
    -shared
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable x11vnc.service
