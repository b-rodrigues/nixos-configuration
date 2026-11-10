#!/bin/sh
# Fuzzy content search using ripgrep + rofi
# Search for text in files and open the result

search_dir="${1:-$HOME}"

# Get search query from rofi
query=$(echo "" | rofi -dmenu -p "Search text" -i \
  -theme-str 'window { width: 500px; }')

if [ -n "$query" ]; then
  # Search with ripgrep, format output, pipe to rofi
  selected=$(rg --line-number --color=never "$query" "$search_dir" 2>/dev/null | \
    head -200 | \
    rofi -dmenu -p "Results" -i \
      -theme-str 'window { width: 1000px; }' \
      -theme-str 'listview { lines: 20; }' \
      -theme-str 'element-text { font: "Iosevka Custom 10"; }')
  
  if [ -n "$selected" ]; then
    # Parse file:line format
    file=$(echo "$selected" | cut -d: -f1)
    line=$(echo "$selected" | cut -d: -f2)
    
    # Open in emacs at specific line
    emacsclient -n "+$line" "$file" || emacs "+$line" "$file" &
  fi
fi

