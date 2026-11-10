#===============================================================================
# Shared waybar top bar definition.
#
# mkMainBar returns the settings.mainBar attrset merged over the shared base:
#
#   settings.mainBar = (pkgs.callPackage ../home/waybar-base.nix { }).mkMainBar {
#     height = 28;           # per-host overrides merge with lib.recursiveUpdate
#     modules-center = [ ];
#   };
#
# Host files keep their own `style` CSS (the MacBook bar is tuned for the
# notch: different paddings, battery selectors, etc.).
#
# NOTE on overrides: `mkMainBar` merges with lib.recursiveUpdate, so LIST keys
# (modules-left/center/right) are REPLACED wholesale, not appended. A host
# that pins its own modules-right list will not pick up base-side module
# additions (or their config blocks) until its list is updated too.
#===============================================================================

{
  lib,
  writeShellScript,
}:
let
  # Solarized Dark palette (modules/home/theme.nix)
  hex = (import ./theme.nix).hex;

  # Single copy of the power-menu script - was previously inlined verbatim in
  # both host waybar configs.
  powerMenu = writeShellScript "rofi-power-menu" (
    builtins.readFile ../scripts/rofi-power-menu.sh
  );
in
{
  mkMainBar =
    perHost:
    lib.recursiveUpdate {
      layer = "top";
      position = "top";
      height = 32;
      spacing = 4;

      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [
        "cpu"
        "memory"
        "wireplumber"
        "tray"
        "custom/power"
      ];

      "hyprland/workspaces" = {
        disable-scroll = true;
        all-outputs = true;
        format = "{name}";
      };

      cpu = {
        format = "cpu: {usage}%";
        tooltip-format = "CPU: {usage}%";
        interval = 1;
        states = {
          warning = 70;
          critical = 90;
        };
      };

      memory = {
        format = "mem: {used:0.1f}G";
        interval = 1;
        tooltip = true;
        tooltip-format = "Memory: {used:0.1f}G / {total:0.1f}G ({percentage}%)";
        on-click = "ghostty htop";
      };

      wireplumber = {
        format = "vol: {volume}%";
        format-muted = "vol: muted";
        scroll-step = 5;
        on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        on-click-right = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 100%";
        tooltip = true;
        tooltip-format = "{node_name}";
      };

      "custom/power" = {
        format = "⏻";
        tooltip = false;
        on-click = "rofi -show power-menu -modi power-menu:${powerMenu}";
      };

      clock = {
        timezone = "Europe/Luxembourg";
        format = "{:%a %d %b  %H:%M}";
        interval = 60;
        on-click = "show-calendar";
        tooltip-format = "<span>{calendar}</span>";
        calendar = {
          mode = "month";
          format = {
            months = "<span color='#${hex.magenta}'><b>{}</b></span>";
            days = "<span color='#${hex.base0}'><b>{}</b></span>";
            weekdays = "<span color='#${hex.green}'><b>{}</b></span>";
            today = "<span color='#${hex.yellow}'><b>{}</b></span>";
          };
        };
      };
    } perHost;
}
