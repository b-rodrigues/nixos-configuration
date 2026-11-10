#!/bin/sh
# Fuzzy file finder using fd + rofi
# Opens selected file in default application or editor

# Get search directory (default to home)
search_dir="${1:-$HOME}"

# Use fd to find files, pipe to rofi for selection
selected=$(fd --type f --hidden --follow --exclude .git . "$search_dir" | \
  rofi -dmenu -p "Find file" -i \
    -theme-str 'window { width: 800px; }' \
    -theme-str 'listview { lines: 20; }')

if [ -n "$selected" ]; then
  # Determine file type and open appropriately
  mime_type=$(file --mime-type -b "$selected")
  
  case "$mime_type" in
    text/*|application/json|application/xml|application/javascript)
      # Open text files in emacsclient
      emacsclient -n "$selected" || emacs "$selected" &
      ;;
    image/*)
      imv "$selected" &
      ;;
    video/*|audio/*)
      mpv "$selected" &
      ;;
    application/pdf)
      xdg-open "$selected" &
      ;;
    *)
      # Default: try xdg-open
      xdg-open "$selected" &
      ;;
  esac
fi

