#!/bin/bash
set -e

sudo pacman -S --noconfirm --needed x11vnc

mkdir -p ~/.vnc
x11vnc -storepasswd ~/.vnc/passwd

sudo tee /etc/systemd/system/x11vnc.service >/dev/null <<EOF
[Unit]
Description=x11vnc VNC Server for Display :0
After=display-manager.service network.target sound.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/bin/x11vnc -auth guess -forever -loop -noxdamage -repeat -rfbauth $HOME/.vnc/passwd -rfbport 5900 -shared
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable x11vnc.service
