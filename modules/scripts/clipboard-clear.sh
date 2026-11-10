#!/bin/sh

choice=$(echo -e "Yes\nNo" | rofi -dmenu -p "Clear clipboard history?" -i)

if [ "$choice" = "Yes" ]; then
    cliphist wipe
    notify-send "Clipboard" "History cleared" -t 2000
fi
