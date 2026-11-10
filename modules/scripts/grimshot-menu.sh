#!/bin/sh

options="📺 Full Screen\n🖱️ Area Selection\n🪟 Current Window\n📋 Area to Clipboard\n📋 Screen to Clipboard\n📋 Window to Clipboard\n⏰ Screen (5s delay)\n⏰ Area (5s delay)"

chosen=$(echo -e "$options" | rofi -dmenu -p "Screenshot" -i -theme-str '
  window { width: 400px; }
  listview { lines: 8; }
')

mkdir -p ~/Pictures/Screenshots

filename="screenshot-$(date +%Y%m%d-%H%M%S).png"
filepath="$HOME/Pictures/Screenshots/$filename"

case "$chosen" in
    "📺 Full Screen")
        grimshot save screen "$filepath"
        notify-send "Screenshot" "Full screen saved to $filename" -i "$filepath"
        ;;
    "🖱️ Area Selection") 
        grimshot save area "$filepath"
        if [ $? -eq 0 ]; then
            notify-send "Screenshot" "Area selection saved to $filename" -i "$filepath"
        fi
        ;;
    "🪟 Current Window")
        grimshot save window "$filepath"
        notify-send "Screenshot" "Window saved to $filename" -i "$filepath"
        ;;
    "📋 Area to Clipboard")
        grimshot copy area
        if [ $? -eq 0 ]; then
            notify-send "Screenshot" "Area selection copied to clipboard"
        fi
        ;;
    "📋 Screen to Clipboard")
        grimshot copy screen
        notify-send "Screenshot" "Full screen copied to clipboard"
        ;;
    "📋 Window to Clipboard")
        grimshot copy window
        notify-send "Screenshot" "Window copied to clipboard"
        ;;
    "⏰ Screen (5s delay)")
        for i in 5 4 3 2 1; do
            notify-send "Screenshot" "Screenshot in $i seconds..." -t 900 -r 999
            sleep 1
        done
        grimshot save screen "$filepath"
        notify-send "Screenshot" "Delayed full screen saved to $filename" -i "$filepath"
        ;;
    "⏰ Area (5s delay)")
        area_result=$(slurp)
        if [ $? -eq 0 ]; then
            for i in 5 4 3 2 1; do
                notify-send "Screenshot" "Area screenshot in $i seconds..." -t 900 -r 999
                sleep 1
            done
            grim -g "$area_result" "$filepath"
            notify-send "Screenshot" "Delayed area selection saved to $filename" -i "$filepath" -r 999
        fi
        ;;
esac
