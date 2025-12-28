#===============================================================================
# Apple Silicon Specific Configuration (MacBook M2)
#
# This module contains settings specific to the MacBook:
# - Asahi firmware
# - Notch kernel parameter
# - iwd WiFi backend
# - Split waybar for notch
#===============================================================================

{
  config,
  pkgs,
  lib,
  ...
}:

{
  #=============================================================================
  # IMPORTS
  #=============================================================================

  imports = [
    ./hardware-configuration.nix
    ./cachix.nix
  ];

  #=============================================================================
  # APPLE SILICON SPECIFIC
  #=============================================================================

  # GPU support is now in mainline mesa, no extra config needed
  # Firmware copied from /boot/asahi into repo for flake compatibility
  hardware.asahi.peripheralFirmwareDirectory = ./firmware;

  #=============================================================================
  # BOOT CONFIGURATION - Apple Silicon specific
  #=============================================================================

  boot = {
    loader.efi.canTouchEfiVariables = false; # Required for Apple Silicon
    # Kernel is provided by apple-silicon-support module

    # Enable the screen area around the MacBook notch
    kernelParams = [ "apple_dcp.show_notch=1" ];
  };

  #=============================================================================
  # NETWORKING - Apple Silicon specific
  #=============================================================================

  networking = {
    hostName = "macbook";
    networkmanager.wifi.backend = "iwd"; # Better for Apple Silicon Broadcom chips
  };

  # iwd is needed as the backend for NetworkManager
  networking.wireless.iwd.enable = true;

  #=============================================================================
  # GRAPHICS - No 32-bit on aarch64
  #=============================================================================

  # Note: 32-bit support not available on aarch64

  #=============================================================================
  # WAYBAR - Split layout for MacBook notch
  #=============================================================================

  home-manager.users.brodrigues =
    { pkgs, ... }:
    {
      programs.waybar = {
        enable = true;
        settings = {
          mainBar = {
            layer = "top";
            position = "top";
            # Height matches the MacBook M2 notch area
            height = 28;
            spacing = 2;

            # Layout optimized for notch: content on sides, center is empty (notch area)
            modules-left = [ "hyprland/workspaces" ];
            modules-center = [ ]; # Empty - this is where the notch sits
            modules-right = [
              "cpu"
              "memory"
              "battery"
              "wireplumber"
              "clock"
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

            battery = {
              format = "bat: {icon} {capacity}%";
              format-icons = [
                ""
                ""
                ""
                ""
                ""
              ];
              format-charging = "bat: ⚡ {capacity}%";
              states = {
                warning = 30;
                critical = 15;
              };
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
              on-click = "rofi -show power-menu -modi power-menu:${pkgs.writeShellScript "rofi-power-menu" ''
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
              ''}";
            };

            clock = {
              timezone = "Europe/Luxembourg";
              format = "{:%m-%d %H:%M}";
              interval = 60;
              on-click = "show-calendar";
              tooltip-format = "<span>{calendar}</span>";
              calendar = {
                mode = "month";
                format = {
                  months = "<span color='#d33682'><b>{}</b></span>";
                  days = "<span color='#839496'><b>{}</b></span>";
                  weekdays = "<span color='#859900'><b>{}</b></span>";
                  today = "<span color='#b58900'><b>{}</b></span>";
                };
              };
            };
          };
        };

        style = ''
          * {
            font-family: "Iosevka Custom", monospace;
            font-size: 11px;
            border: none;
            border-radius: 0;
            min-height: 0;
          }

          window#waybar {
            background-color: #002b36;
            border-bottom: 2px solid #073642;
            color: #839496;
            transition-property: background-color;
            transition-duration: .5s;
          }

          #workspaces button {
            padding: 0 5px;
            background-color: transparent;
            color: #586e75;
            border: none;
            border-radius: 0;
          }

          #workspaces button:hover {
            background-color: #073642;
            color: #839496;
          }

          #workspaces button.active {
            background-color: #d33682;
            color: #fdf6e3;
            border-bottom: 2px solid #dc322f;
          }

          #cpu, #memory, #clock, #wireplumber, #tray, #battery {
            padding: 0 6px;
            color: #839496;
            margin: 0 1px;
            font-size: 13px;
          }

          #cpu {
            color: #268bd2;
          }

          #memory {
            color: #859900;
          }

          #battery {
            color: #2aa198;
          }

          #battery.warning {
            color: #b58900;
          }

          #battery.critical {
            color: #dc322f;
          }

          #wireplumber {
            color: #cb4b16;
          }

          #wireplumber.muted {
            color: #dc322f;
          }

          #clock {
            color: #b58900;
            font-weight: bold;
            padding: 0 4px;
            min-width: 0;
          }

          #custom-power {
            color: #dc322f;
            font-size: 13px;
            padding: 0 8px;
          }

          #tray {
            color: #6c71c4;
            margin-left: 15px;
          }

          tooltip {
            background-color: #073642;
            color: #839496;
            border: 1px solid #586e75;
            border-radius: 3px;
          }
        '';
      };

      # Home Manager state version for this machine
      home.stateVersion = "25.05";
    };

  #=============================================================================
  # SYSTEM VERSION - Set once at install, update only for fresh installs
  #=============================================================================

  system.stateVersion = "25.11";
}
