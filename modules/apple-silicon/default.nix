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
  pkgs-unstable,
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

  # Bridge avd-fw and asahi-va-driver from nixpkgs-unstable when the ambient
  # release-26.05 set does not package them yet (see flake.nix inputs comment)
  nixpkgs.overlays = [
    (final: prev: {
      avd-fw = prev.avd-fw or pkgs-unstable.avd-fw;
      asahi-va-driver = prev.asahi-va-driver or pkgs-unstable.asahi-va-driver;

      # nixpkgs packages libva-v4l2_request at sofus13's 1.3 tag, which decodes
      # into buffers it allocates itself. Chromium instead creates a surface,
      # exports it as a dma-buf, imports it into the GPU and only then decodes
      # into it, so the buffers the browser samples stay all-zero -- solid green
      # video (X/Twitter, embedded players) while audio and the timeline look
      # fine. mpv/FFmpeg never hit this because they decode in their own order.
      # This fork decodes into the client's exported surfaces; it also carries
      # further AVD fixes (HEVC slice parsing, 10-bit backing, firmware hangs).
      # Revert to `prev` if AVD playback regresses.
      libva-v4l2_request-sofus13 = prev.libva-v4l2_request-sofus13.overrideAttrs (
        old: rec {
          version = "1.3.r11";
          name = "${old.pname}-${version}";
          src = final.fetchFromGitHub {
            owner = "omacom";
            repo = "libva-v4l2_request";
            rev = "4f60c51f7841dd74bb61c94a4ad31e630bbdab01";
            hash = "sha256-+M2XnhPP/vdNZqBZcQ1nk/EXZFHdDGPAbvF67AK1J5A=";
          };
        }
      );
    })
  ];

  #=============================================================================
  # APPLE SILICON SPECIFIC
  #=============================================================================

  hardware.asahi.enable = true;
  # GPU support is now in mainline mesa, no extra config needed
  # Firmware copied from /boot/asahi into repo for flake compatibility
  hardware.asahi.peripheralFirmwareDirectory = ./firmware;

  # Apple Video Decoder (AVD) hardware acceleration (H.264, HEVC, VP9)
  hardware.asahi.avd.enable = lib.mkDefault true;
  hardware.asahi.avd.vaapi-support = true;

  #=============================================================================
  # BOOT CONFIGURATION - Apple Silicon specific
  #=============================================================================

  boot = {
    loader.efi.canTouchEfiVariables = false; # Required for Apple Silicon
    loader.systemd-boot.graceful = true;     # Treat EFI var write failures as warnings, not errors
    # Kernel is provided by apple-silicon-support module

    # Enable the screen area around the MacBook notch
    kernelParams = [ "appledrm.show_notch=1" ];
  };

  boot.kernel.sysctl."vm.mmap_rnd_bits" = lib.mkForce 18;

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
    let
      # Shared bar definition (modules/home/waybar-base.nix)
      waybarBase = pkgs.callPackage ../home/waybar-base.nix { };
    in
    {
      programs.waybar = {
        enable = true;

        # Shared bar definition (modules/home/waybar-base.nix), tuned for
        # the notch: content on the sides, centre is empty (notch area).
        settings.mainBar = waybarBase.mkMainBar {
          # Height matches the MacBook M2 notch area
          height = 28;
          spacing = 2;

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

          clock.format = "{:%m-%d %H:%M}";
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
