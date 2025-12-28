#===============================================================================
# Desktop (x86_64) Specific Configuration
#
# This module contains settings specific to the desktop PC:
# - NVIDIA GPU support (optional)
# - 32-bit graphics/audio support
# - libvirtd/virt-manager
# - Samsung printer driver
# - Standard single waybar layout
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
  ]
  ++ (builtins.filter (f: builtins.pathExists f) [
    ./nvidia.nix # NVIDIA configuration (optional)
  ]);

  #=============================================================================
  # BOOT CONFIGURATION - Desktop specific
  #=============================================================================

  boot = {
    loader.efi.canTouchEfiVariables = true;
    # Use latest kernel for best hardware support
    kernelPackages = pkgs.linuxPackages_6_17;
  };

  #=============================================================================
  # NETWORKING - Desktop specific
  #=============================================================================

  networking.hostName = "nixos";

  #=============================================================================
  # GRAPHICS - 32-bit support for x86_64
  #=============================================================================

  hardware.graphics.enable32Bit = true;

  #=============================================================================
  # FONTS - 32-bit cache
  #=============================================================================

  fonts.fontconfig.cache32Bit = true;

  #=============================================================================
  # AUDIO - 32-bit support
  #=============================================================================

  services.pipewire.alsa.support32Bit = true;

  #=============================================================================
  # VIRTUALIZATION
  #=============================================================================

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  # Add libvirtd group to user
  users.users.brodrigues.extraGroups = lib.mkAfter [ "libvirtd" ];

  #=============================================================================
  # PRINTING - Samsung driver (x86 only)
  #=============================================================================

  services.printing.drivers = [ pkgs.samsung-unified-linux-driver ];

  #=============================================================================
  # Desktop-specific packages
  #=============================================================================

  environment.systemPackages = with pkgs; [
    air-formatter # Format R code (may not be available on aarch64)
    codex # OpenAI Codex
  ];

  #=============================================================================
  # WAYBAR - Standard single bar layout (no notch)
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
            height = 32;
            spacing = 4;

            # Standard centered layout
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
              format = "{:%a %d %b  %H:%M}";
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
            font-size: 13px;
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
            padding: 0 8px;
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

          #cpu, #memory, #clock, #wireplumber, #tray {
            padding: 0 10px;
            color: #839496;
            margin: 0 2px;
          }

          #cpu {
            color: #268bd2;
          }

          #memory {
            color: #859900;
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
          }

          #custom-power {
            color: #dc322f;
            font-size: 14px;
            padding: 0 12px;
          }

          #tray {
            color: #6c71c4;
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
