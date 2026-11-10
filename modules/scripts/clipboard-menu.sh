#!/bin/sh

clips=$(cliphist list 2>/dev/null)

if [ -z "$clips" ]; then
    options="📋 Current Clipboard\n📝 Copy Text\n❓ Help"
    
    chosen=$(echo -e "$options" | rofi -dmenu -p "Clipboard (No History)" -i)
    
    case "$chosen" in
        "📋 Current Clipboard")
            current=$(wl-paste 2>/dev/null || echo "Clipboard is empty")
            echo "$current" | rofi -dmenu -p "Current Clipboard:" -theme-str 'window { width: 600px; }'
            ;;
        "📝 Copy Text")
            text=$(echo "" | rofi -dmenu -p "Enter text to copy:" -theme-str 'window { width: 500px; }')
            if [ -n "$text" ]; then
                echo -n "$text" | wl-copy
                notify-send "Clipboard" "Text copied - history will start building" -t 3000
            fi
            ;;
        "❓ Help")
            notify-send "Clipboard Help" "Copy something (Ctrl+C or select with mouse) to start building history" -t 5000
            ;;
    esac
    exit 0
fi

clips=$(echo "$clips" | head -20 | cut -c1-100)

chosen=$(echo "$clips" | rofi -dmenu -p "Clipboard History" -i \
    -theme-str 'window { width: 800px; } listview { lines: 15; }' \
    -theme-str 'element-text { font: "Iosevka Custom 11"; }')

if [ -n "$chosen" ]; then
    echo "$chosen" | cliphist decode | wl-copy
    notify-send "Clipboard" "Item copied to clipboard" -t 2000
fi
