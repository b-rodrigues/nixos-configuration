#!/bin/sh

case $1 in
  "")
    echo "logout"
    echo "reboot"
    echo "shutdown"
    ;;
  "logout")
    hyprctl dispatch exit
    ;;
  "reboot")
    systemctl reboot
    ;;
  "shutdown")
    systemctl poweroff
    ;;
esac

