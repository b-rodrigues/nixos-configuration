#===============================================================================
# Common NixOS Configuration - Shared between Desktop and Apple Silicon
# Author: Bruno Rodrigues and Claude
#
# This configuration provides shared settings for both machines:
# - Hyprland window manager with BÉPO keyboard layout
# - Solarized Dark theme throughout
# - Development tools (Emacs, Git, direnv)
# - Modern applications (Brave from the ambient release-26.05 set, GIMP, etc.)
#===============================================================================

{
  config,
  pkgs,
  pkgs-unstable,
  pkgs-opencodev2,
  inputs,
  lib,
  ...
}:

{
  #=============================================================================
  # Shared flake inputs (bootvine module, used below)
  #=============================================================================

  imports = [
    inputs.bootvine.nixosModules.default
    ./scripts.nix
    ./home/base.nix
  ];

  #=============================================================================
  # Trusted users
  #=============================================================================

  nix.settings.trusted-users = [
    "root"
    "@wheel"
  ];

  #=============================================================================
  # Firewall configuration
  #=============================================================================

  networking.firewall.allowedTCPPorts = [ 8080 ];

  #=============================================================================
  # Garbage collection
  #=============================================================================

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.settings.auto-optimise-store = true;

  #=============================================================================
  # Experimental features
  #=============================================================================

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  #=============================================================================
  # BOOT - Common settings (systemd-boot)
  #=============================================================================

  boot.loader.systemd-boot.enable = true;

  #=============================================================================
  # BOOTVINE - Live dependency tree of systemd jobs on the boot console
  # Shows during boot (initrd + stage 2), shutdown and reboot.
  # https://codeberg.org/wvhulle/bootvine
  #=============================================================================

  services.bootvine.enable = true;

  #=============================================================================
  # GRAPHICS CONFIGURATION - Base
  #=============================================================================

  hardware.graphics.enable = true;

  #=============================================================================
  # Hardware
  #=============================================================================

  hardware.keyboard.zsa.enable = true;

  # Compressed RAM swap, very fast
  zramSwap.enable = true;

  #=============================================================================
  # Docker (rootless)
  #=============================================================================
  virtualisation.docker = {
    enable = true;
  
    rootless = {
      enable = true;
      setSocketVariable = true;
      daemon.settings = { };  # This forces creation of the user service
    };
  };

  systemd.user.services.docker = {
    wantedBy = [ "default.target" ];
  };

  #=============================================================================
  # OpenCode v2 background server
  # Started at login; opencode2 clients also auto-start it on demand.
  # Used by the 'llm' command and the OpenCode TUI/desktop app.
  #=============================================================================

  systemd.user.services.opencode2 = {
    wantedBy = [ "default.target" ];
    description = "OpenCode v2 background server";
    serviceConfig = {
      ExecStart = "${pkgs-opencodev2.opencode2}/bin/opencode2 serve --service";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };

  #=============================================================================
  # NETWORK & LOCALIZATION - Common
  #=============================================================================

  networking.networkmanager.enable = true;

  # European settings for Luxembourg
  time.timeZone = "Europe/Luxembourg";
  i18n.defaultLocale = "en_GB.UTF-8";

  #=============================================================================
  # POLICYKIT
  #=============================================================================

  security.polkit.enable = true;

  #=============================================================================
  # INPUT CONFIGURATION
  # BÉPO keyboard layout for efficient French typing
  #=============================================================================

  console.keyMap = "fr";

  #=============================================================================
  # DISPLAY MANAGER & DESKTOP ENVIRONMENT
  #=============================================================================

  services = {
    xserver = {
      enable = true;
      xkb = {
        layout = "fr";
        variant = "bepo";
        options = "caps:escape";
      };
    };

    displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
      };
      defaultSession = "hyprland";
      autoLogin = {
        enable = true;
        user = "brodrigues";
      };
    };

    desktopManager.plasma6.enable = true;

    tailscale.enable = true;
  };

  #=============================================================================
  # TYPOGRAPHY & FONTS - Common
  #=============================================================================

  fonts = {
    packages = with pkgs; [
      liberation_ttf
      source-code-pro
      freetype
      fontconfig
    ];

    fontconfig = {
      enable = true;
      antialias = true;

      hinting = {
        enable = true;
        style = "slight";
      };
      subpixel.rgba = "rgb";

      defaultFonts = {
        monospace = [
          "Iosevka Custom"
          "Source Code Pro"
        ];
        sansSerif = [ "Liberation Sans" ];
        serif = [ "Liberation Serif" ];
      };
    };
  };

  #=============================================================================
  # AUDIO SYSTEM
  #=============================================================================

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  #=============================================================================
  # SYSTEM SERVICES
  #=============================================================================

  services.printing.enable = true;

  #=============================================================================
  # USER ACCOUNT CONFIGURATION
  #=============================================================================

  users.users.brodrigues = {
    isNormalUser = true;
    description = "Bruno Rodrigues";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  #=============================================================================
  # PACKAGE MANAGEMENT & SYSTEM PACKAGES
  #=============================================================================

  nixpkgs.config.allowUnfree = true;

  environment = {
    systemPackages = with pkgs; [

      # Development & AI Tools
      aider-chat
      pkgs-unstable.antigravity-cli
      pkgs-opencodev2.opencode2
      (pkgs.callPackage ./pkgs/freebuff/package.nix { })
      jq

      # Web & Communication
      # Chromium renders an all-zero video surface as solid green. It creates a
      # surface, exports it as a dma-buf, imports it into the GPU and only then
      # decodes into it; when the driver writes to its own buffers instead, the
      # frame the browser samples stays zeroed, which is exactly what the
      # NVIDIA stack does. Software decoding skips that import path, so affected
      # videos (X/Twitter, embedded players) render again; YouTube was never hit
      # because it usually ends up on a software-decoded codec.
      # The macbook does not need this: modules/apple-silicon replaces
      # libva-v4l2_request with a fork that decodes into the exported buffers,
      # so hardware decoding works there and is left enabled.
      (pkgs.brave.override {
        commandLineArgs = lib.optionalString (!(config.hardware.asahi.enable or false)) "--disable-accelerated-video-decode";
      })

      # System Utilities
      cachix
      docker-compose
      pavucontrol
      libnotify
      htop
      btop
      krusader
      wget
      lxqt.lxqt-policykit
      tree
      ispell
      fastfetch
      brightnessctl
      networkmanagerapplet
      fd
      ripgrep

      # Screen recording and video tools
      obs-studio
      ffmpeg-full
      shotcut
      mpv
      vlc
      themechanger

      # Additional codecs
      x264
      x265
      libvpx

      # Wayland Tools
      cliphist
      grim
      imv
      slurp
      sway-contrib.grimshot
      awww
      waybar
      hypridle
      wl-clipboard

      # Applications
      gimp3

    ];

    sessionVariables = {
      QT_QPA_PLATFORMTHEME = "kde";
      QT_QPA_PLATFORM = "wayland";
      QT_STYLE_OVERRIDE = "breeze";
      GDK_SCALE = "1";
      GDK_DPI_SCALE = "1.5";
      QT_SCALE_FACTOR = "1.5";
      NIXOS_OZONE_WL = "1";
      XDG_SESSION_TYPE = "wayland";
    };
  };

  #=============================================================================
  # SYSTEM PROGRAMS & GLOBAL CONFIGURATION
  #=============================================================================

  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    git = {
      enable = true;
      lfs.enable = true;
      config = {
        user = {
          name = "Bruno Rodrigues";
          email = "bruno@brodrigues.co";
        };
      };
    };

    dconf.enable = true;
  };

  #=============================================================================
  # HOME MANAGER CONFIGURATION
  #=============================================================================

  # Required for Home Manager's NixOS module to create the per-user activation
  # service (home-manager-brodrigues.service). Without these two flags the
  # module silently skips activation even when home-manager.users is configured.
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  # Back up any pre-existing files HM wants to manage (instead of hard-failing).
  home-manager.backupFileExtension = "bak";

  #=============================================================================
  # HOME MANAGER - SHARED USER CONFIGURATION
  #
  # Shared per-user configuration lives in modules/home/base.nix (imported
  # above); host-specific entries live in modules/desktop and
  # modules/apple-silicon.
  #=============================================================================

  # system.stateVersion is set in platform-specific modules
  # (allows different versions for fresh installs on new hardware)
}
