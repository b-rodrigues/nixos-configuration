#===============================================================================
# Solarized Dark palette - single source of truth
#
# Imported wherever a color from the theme is needed (kdeglobals, dunst,
# fzf, starship, hyprland, ghostty, waybar) so retuning the theme happens
# in exactly one file.
#
# `hex`  holds the 6-digit codes WITHOUT the leading '#': consumers that
#        want the CSS-style form interpolate it back in ("#${hex.base03}"),
#        and consumers with their own syntax prefix (hyprland's
#        rgb(...), ghostty/awww bare codes) use the value as-is.
# `rgb`  holds the comma-separated R,G,B triplet form that KDE's
#        kdeglobals expects.
# https://ethanschoonover.com/solarized/
#===============================================================================
{
  hex = {
    base03 = "002b36";
    base02 = "073642";
    base01 = "586e75";
    base00 = "657b83";
    base0  = "839496";
    base1  = "93a1a1";
    base2  = "eee8d5";
    base3  = "fdf6e3";
    yellow = "b58900";
    orange = "cb4b16";
    red    = "dc322f";
    magenta = "d33682";
    violet = "6c71c4";
    blue   = "268bd2";
    cyan   = "2aa198";
    green  = "859900";
  };

  rgb = {
    base03 = "0,43,54";
    base02 = "7,54,66";
    base01 = "88,110,117";
    base00 = "101,123,131";
    base0  = "131,148,150";
    base1  = "147,161,161";
    base2  = "238,232,213";
    base3  = "253,246,227";
    yellow = "181,137,0";
    orange = "203,75,22";
    red    = "220,50,47";
    magenta = "211,54,130";
    violet = "108,113,196";
    blue   = "38,139,210";
    cyan   = "42,161,152";
    green  = "133,153,0";
  };
}
