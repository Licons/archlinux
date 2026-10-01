#!/usr/bin/env bash

set -e

systemctl --user add-wants niri.service dms.service

echo
echo "DMS enabled."
echo "Logout/login lại để áp dụng."

sleep 1

reboot