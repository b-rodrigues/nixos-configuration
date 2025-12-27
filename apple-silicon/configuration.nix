#===============================================================================
# NixOS Configuration for Bruno's Hyprland Desktop - Apple Silicon Edition
# Author: Bruno Rodrigues and Claude
# 
# This configuration provides a complete Wayland desktop environment with:
# - Hyprland window manager with BÉPO keyboard layout
# - Apple Silicon hardware support (M2 MacBook Air)
# - Solarized Dark theme throughout
# - Development tools (Emacs, Git, direnv)
# - Modern applications (Brave from nixpkgs.unstable, GIMP, etc.)
#
# Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').
#===============================================================================

{ config, pkgs, pkgs-unstable, ... }:

{
  #=============================================================================
  # SYSTEM IMPORTS
  #=============================================================================
  
  imports = [
    ./hardware-configuration.nix    # Hardware-specific settings
    ./cachix.nix                    # Binary cache (includes nix-community for faster builds)
  ];

  #=============================================================================
  # APPLE SILICON SPECIFIC CONFIGURATION
  #=============================================================================

  # GPU support is now in mainline mesa, no extra config needed
  # Firmware copied from /boot/asahi into repo for flake compatibility
  hardware.asahi.peripheralFirmwareDirectory = ./firmware;

  #=============================================================================
  # Trusted users
  #=============================================================================

  nix.settings.trusted-users = [ "root" "@wheel" ];

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

   nix.settings.experimental-features = [ "nix-command" "flakes" ];

  #=============================================================================
  # BOOT & KERNEL CONFIGURATION
  #=============================================================================
  
  boot = {
    loader = {
      systemd-boot.enable = true;
      # IMPORTANT: Must be false on Apple Silicon
      efi.canTouchEfiVariables = false;
    };
    # Kernel is provided by apple-silicon-support module - don't override it
    
    # Enable the screen area around the MacBook notch
    # This makes the "ears" beside the notch usable for status bars
    kernelParams = [ "apple_dcp.show_notch=1" ];
  };

  #=============================================================================
  # GRAPHICS CONFIGURATION
  #=============================================================================
  
  hardware.graphics = {
    enable = true;
    # Note: 32-bit support not available on aarch64
  };

  #=============================================================================
  # Hardware
  #=============================================================================

  hardware.keyboard.zsa.enable = true;

  # Compressed RAM swap, very fast
  zramSwap.enable = true;

  #=============================================================================
  # Docker (rootless works on Apple Silicon)
  #=============================================================================

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  # Note: libvirtd/QEMU works on Apple Silicon but performance may vary
  # Uncomment if you need it:
  # virtualisation.libvirtd.enable = true;
  # programs.virt-manager.enable = true;

  #=============================================================================
  # NETWORK & LOCALIZATION
  #=============================================================================

  networking = {
    hostName = "macbook";
    networkmanager = {
      enable = true;
      # Use iwd as the WiFi backend (better for Apple Silicon broadcom chips)
      wifi.backend = "iwd";
    };
  };

  # iwd is still needed as the backend for NetworkManager
  networking.wireless.iwd.enable = true;

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
  
  services.xserver.xkb = {
    layout = "fr";
    variant = "bepo";
    options = "caps:escape";
  };
  
  console.keyMap = "fr";

  #=============================================================================
  # DISPLAY MANAGER & DESKTOP ENVIRONMENT
  #=============================================================================
  
  services = {
    xserver.enable = true;
    
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
  };

  #=============================================================================
  # TYPOGRAPHY & FONTS
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
      # Note: cache32Bit not available on aarch64
      
      hinting = {
        enable = true;
        style = "slight";
      };
      subpixel.rgba = "rgb";
      
      defaultFonts = {
        monospace = [ "Iosevka Custom" "Source Code Pro" ];
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
    # Note: 32-bit support not available on aarch64
    pulse.enable = true;
  };

  #=============================================================================
  # SYSTEM SERVICES
  #=============================================================================
  
  services.printing.enable = true;
  # Note: samsung-unified-linux-driver removed (x86 only)

  #=============================================================================
  # USER ACCOUNT CONFIGURATION
  #=============================================================================
  
  users.users.brodrigues = {
    isNormalUser = true;
    description = "Bruno Rodrigues";
    extraGroups = [ 
      # "libvirtd"         # Uncomment if using libvirtd
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

      #=============================================================================
      # Custom Script: nixpr-review
      #=============================================================================
      (pkgs.writeShellScriptBin "nixpr-review" ''
        #!/usr/bin/env bash
      
        set -e
        if [ $# -lt 2 ]; then
            echo "Usage: $0 <nixpkgs-commit-hash> <package-name1> [<package-name2> ...]"
            exit 1
        fi
        COMMIT_HASH="$1"
        shift
        PACKAGES=("$@")
        NIXPKGS_URL="https://github.com/NixOS/nixpkgs/archive/''${COMMIT_HASH}.tar.gz"
        NIXPKGS_PATH="nixpkgs-''${COMMIT_HASH}"
      
        if [ ! -d "$NIXPKGS_PATH" ]; then
            echo "Downloading nixpkgs at commit $COMMIT_HASH..."
            curl -L "$NIXPKGS_URL" -o "''${COMMIT_HASH}.tar.gz"
            tar -xzf "''${COMMIT_HASH}.tar.gz"
            rm "''${COMMIT_HASH}.tar.gz"
        fi
        nix-shell -I nixpkgs="./''${NIXPKGS_PATH}" -p "''${PACKAGES[@]}"
      '')

      # Development & AI Tools
      aider-chat
      antigravity
      jq
      
      # Web & Communication
      pkgs-unstable.brave
      
      # System Utilities
      cachix
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
      brightnessctl               # For laptop brightness control
      networkmanagerapplet        # Network management GUI
      fd                          # Fast find alternative (used by fzf)
      ripgrep                     # Fast grep alternative

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
      swww
      waybar
      hypridle
      wl-clipboard
      
      # Applications
      gimp3

      # Scripts to put in PATH
      (pkgs.writeShellScriptBin "grimshot-menu" ''
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
                    ${pkgs.coreutils}/bin/sleep 1
                done
                grimshot save screen "$filepath"
                notify-send "Screenshot" "Delayed full screen saved to $filename" -i "$filepath"
                ;;
            "⏰ Area (5s delay)")
                area_result=$(slurp)
                if [ $? -eq 0 ]; then
                    for i in 5 4 3 2 1; do
                        notify-send "Screenshot" "Area screenshot in $i seconds..." -t 900 -r 999
                        ${pkgs.coreutils}/bin/sleep 1
                    done
                    grim -g "$area_result" "$filepath"
                    notify-send "Screenshot" "Delayed area selection saved to $filename" -i "$filepath" -r 999
                fi
                ;;
        esac
      '')

      (pkgs.writeShellScriptBin "clipboard-menu" ''
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
      '')
      
      (pkgs.writeShellScriptBin "clipboard-clear" ''
        #!/bin/sh
        
        choice=$(echo -e "Yes\nNo" | rofi -dmenu -p "Clear clipboard history?" -i)
        
        if [ "$choice" = "Yes" ]; then
            cliphist wipe
            notify-send "Clipboard" "History cleared" -t 2000
        fi
      '')

      (pkgs.writeShellScriptBin "rofi-files" ''
        #!/bin/sh
        # Fuzzy file finder using fd + rofi
        # Opens selected file in default application or editor
        
        # Get search directory (default to home)
        search_dir="''${1:-$HOME}"
        
        # Use fd to find files, pipe to rofi for selection
        selected=$(${pkgs.fd}/bin/fd --type f --hidden --follow --exclude .git . "$search_dir" | \
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
      '')

      (pkgs.writeShellScriptBin "rofi-grep" ''
        #!/bin/sh
        # Fuzzy content search using ripgrep + rofi
        # Search for text in files and open the result
        
        search_dir="''${1:-$HOME}"
        
        # Get search query from rofi
        query=$(echo "" | rofi -dmenu -p "Search text" -i \
          -theme-str 'window { width: 500px; }')
        
        if [ -n "$query" ]; then
          # Search with ripgrep, format output, pipe to rofi
          selected=$(${pkgs.ripgrep}/bin/rg --line-number --color=never "$query" "$search_dir" 2>/dev/null | \
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
      '')
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
  
  home-manager.users.brodrigues = { pkgs, ... }: {
    home.stateVersion = "25.05";

    qt = {
      enable = true;
      platformTheme.name = "kde";
      style.name = "breeze";
    };

    # Install Breeze themes and icons for Qt apps (Qt6 only, Plasma 6 handles Qt5 fallback)
    home.packages = with pkgs; [
      kdePackages.breeze
      kdePackages.breeze-icons
    ];

    # Solarized Dark color scheme for KDE/Qt apps
    xdg.configFile."kdeglobals" = {
      force = true;
      text = ''
      [ColorEffects:Disabled]
      Color=0,43,54
      ColorAmount=0
      ColorEffect=0
      ContrastAmount=0.65
      ContrastEffect=1
      IntensityAmount=0.1
      IntensityEffect=2

      [ColorEffects:Inactive]
      ChangeSelectionColor=true
      Color=88,110,117
      ColorAmount=0.025
      ColorEffect=2
      ContrastAmount=0.1
      ContrastEffect=2
      Enable=false
      IntensityAmount=0
      IntensityEffect=0

      [Colors:Button]
      BackgroundAlternate=0,43,54
      BackgroundNormal=7,54,66
      DecorationFocus=38,139,210
      DecorationHover=38,139,210
      ForegroundActive=38,139,210
      ForegroundInactive=88,110,117
      ForegroundLink=38,139,210
      ForegroundNegative=220,50,47
      ForegroundNeutral=203,75,22
      ForegroundNormal=131,148,150
      ForegroundPositive=133,153,0
      ForegroundVisited=108,113,196

      [Colors:Complementary]
      BackgroundAlternate=0,43,54
      BackgroundNormal=7,54,66
      DecorationFocus=38,139,210
      DecorationHover=38,139,210
      ForegroundActive=38,139,210
      ForegroundInactive=88,110,117
      ForegroundLink=38,139,210
      ForegroundNegative=220,50,47
      ForegroundNeutral=203,75,22
      ForegroundNormal=131,148,150
      ForegroundPositive=133,153,0
      ForegroundVisited=108,113,196

      [Colors:Header]
      BackgroundAlternate=7,54,66
      BackgroundNormal=7,54,66
      DecorationFocus=38,139,210
      DecorationHover=38,139,210
      ForegroundActive=38,139,210
      ForegroundInactive=88,110,117
      ForegroundLink=38,139,210
      ForegroundNegative=220,50,47
      ForegroundNeutral=203,75,22
      ForegroundNormal=131,148,150
      ForegroundPositive=133,153,0
      ForegroundVisited=108,113,196

      [Colors:Header][Inactive]
      BackgroundAlternate=7,54,66
      BackgroundNormal=7,54,66
      DecorationFocus=38,139,210
      DecorationHover=38,139,210
      ForegroundActive=38,139,210
      ForegroundInactive=88,110,117
      ForegroundLink=38,139,210
      ForegroundNegative=220,50,47
      ForegroundNeutral=203,75,22
      ForegroundNormal=131,148,150
      ForegroundPositive=133,153,0
      ForegroundVisited=108,113,196

      [Colors:Selection]
      BackgroundAlternate=0,43,54
      BackgroundNormal=38,139,210
      DecorationFocus=38,139,210
      DecorationHover=38,139,210
      ForegroundActive=131,148,150
      ForegroundInactive=88,110,117
      ForegroundLink=147,161,161
      ForegroundNegative=220,50,47
      ForegroundNeutral=203,75,22
      ForegroundNormal=131,148,150
      ForegroundPositive=133,153,0
      ForegroundVisited=108,113,196

      [Colors:Tooltip]
      BackgroundAlternate=7,54,66
      BackgroundNormal=7,54,66
      DecorationFocus=38,139,210
      DecorationHover=38,139,210
      ForegroundActive=38,139,210
      ForegroundInactive=88,110,117
      ForegroundLink=38,139,210
      ForegroundNegative=220,50,47
      ForegroundNeutral=203,75,22
      ForegroundNormal=131,148,150
      ForegroundPositive=133,153,0
      ForegroundVisited=108,113,196

      [Colors:View]
      BackgroundAlternate=7,54,66
      BackgroundNormal=0,43,54
      DecorationFocus=38,139,210
      DecorationHover=38,139,210
      ForegroundActive=38,139,210
      ForegroundInactive=88,110,117
      ForegroundLink=38,139,210
      ForegroundNegative=220,50,47
      ForegroundNeutral=203,75,22
      ForegroundNormal=131,148,150
      ForegroundPositive=133,153,0
      ForegroundVisited=108,113,196

      [Colors:Window]
      BackgroundAlternate=7,54,66
      BackgroundNormal=7,54,66
      DecorationFocus=38,139,210
      DecorationHover=38,139,210
      ForegroundActive=38,139,210
      ForegroundInactive=88,110,117
      ForegroundLink=38,139,210
      ForegroundNegative=220,50,47
      ForegroundNeutral=203,75,22
      ForegroundNormal=131,148,150
      ForegroundPositive=133,153,0
      ForegroundVisited=108,113,196

      [General]
      ColorScheme=SolarizedDark
      Name=Breeze Solarized Dark
      shadeSortColumn=true

      [KDE]
      contrast=4

      [WM]
      activeBackground=7,54,66
      activeBlend=131,148,150
      activeForeground=131,148,150
      inactiveBackground=7,54,66
      inactiveBlend=88,110,117
      inactiveForeground=88,110,117
    '';
    };

  gtk = {
    enable = true;

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };


    xresources.properties = {
      "Xft.dpi" = "144";
    };

    #---------------------------------------------------------------------------
    # Hypridle service configuration
    #---------------------------------------------------------------------------
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          ignore_dbus_inhibit = false;
        };

        listener = [
          {
            timeout = 300;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
        ];
      };
    };

    #---------------------------------------------------------------------------
    # NOTIFICATION SYSTEM
    #---------------------------------------------------------------------------
    services.dunst = {
      enable = true;
      settings = {
        global = {
          monitor = 0;
          follow = "mouse";
          geometry = "300x60-20+20";
          indicate_hidden = "yes";
          shrink = "no";
          transparency = 10;
          notification_height = 0;
          separator_height = 2;
          padding = 8;
          horizontal_padding = 8;
          frame_width = 2;
          frame_color = "#d33682";
          separator_color = "frame";
          sort = "yes";
          idle_threshold = 120;
          font = "Iosevka Custom 12";
          line_height = 0;
          markup = "full";
          format = "<b>%s</b>\n%b";
          alignment = "left";
          show_age_threshold = 60;
          word_wrap = "yes";
          ellipsize = "middle";
          ignore_newline = "no";
          stack_duplicates = true;
          hide_duplicate_count = false;
          show_indicators = "yes";
          icon_position = "left";
          max_icon_size = 32;
          sticky_history = "yes";
          history_length = 20;
          browser = "brave";
          always_run_script = true;
          title = "Dunst";
          class = "Dunst";
          startup_notification = false;
          verbosity = "mesg";
          corner_radius = 5;
        };
    
        experimental = {
          per_monitor_dpi = false;
        };
    
        urgency_low = {
          background = "#002b36";
          foreground = "#839496";
          timeout = 10;
        };
    
        urgency_normal = {
          background = "#073642";
          foreground = "#839496";
          timeout = 10;
        };
    
        urgency_critical = {
          background = "#dc322f";
          foreground = "#fdf6e3";
          frame_color = "#dc322f";
          timeout = 0;
        };
      };
    };

    #---------------------------------------------------------------------------
    # Nix-direnv
    #---------------------------------------------------------------------------
    programs.direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };
    
    #---------------------------------------------------------------------------
    # SHELL ENVIRONMENT
    #---------------------------------------------------------------------------
    programs.bash = {
      enable = true;
      
      shellAliases = {
        ll = "ls -alF";
        la = "ls -A";
        l = "ls -CF";
        ".." = "cd ..";
        "..." = "cd ../..";

        grep = "grep --color=auto";
        fgrep = "fgrep --color=auto";
        egrep = "egrep --color=auto";
        
        # NixOS system management - updated for Apple Silicon
        rebuild = "sudo nixos-rebuild switch --flake /home/brodrigues/Documents/repos/nixos-configuration/apple-silicon#macbook";
        upgrade = "cd /home/brodrigues/Documents/repos/nixos-configuration/apple-silicon && nix flake update && sudo nixos-rebuild switch --flake /home/brodrigues/Documents/repos/nixos-configuration/apple-silicon#macbook";
        rebuild-test = "sudo nixos-rebuild test --flake /home/brodrigues/Documents/repos/nixos-configuration/apple-silicon#macbook";
        rebuild-dry = "sudo nixos-rebuild dry-build --flake /home/brodrigues/Documents/repos/nixos-configuration/apple-silicon#macbook";
        rollback = "sudo nixos-rebuild switch --rollback";
        gc = "sudo nix-collect-garbage -d && nix-collect-garbage -d";
      };
      
      bashrcExtra = ''
        #=====================================================================
        # HISTORY CONFIGURATION
        #=====================================================================
        export HISTSIZE=10000
        export HISTFILESIZE=20000
        export HISTCONTROL=ignoreboth:erasedups
        shopt -s histappend

        #=====================================================================
        # SOLARIZED DARK COLOR SCHEME FOR LS
        #=====================================================================
        
        export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'
        
        #=====================================================================
        # UTILITY FUNCTIONS
        #=====================================================================
        
        mkcd() {
          mkdir -p "$1" && cd "$1"
        }
        
        gst() {
          git status --short --branch
        }

        keys() {
          echo ""
          echo -e "\033[1;33m╭──────────────────────────────────────────────────────╮\033[0m"
          echo -e "\033[1;33m│\033[0m \033[1;36m Terminal Shortcuts (fzf)\033[0m                          \033[1;33m│\033[0m"
          echo -e "\033[1;33m├──────────────────────────────────────────────────────┤\033[0m"
          echo -e "\033[1;33m│\033[0m  \033[1;32mCtrl+T\033[0m     Fuzzy find file, cd to its directory                   \033[1;33m│\033[0m"
          echo -e "\033[1;33m│\033[0m  \033[1;32mCtrl+F\033[0m     Fuzzy find file (insert path)           \033[1;33m│\033[0m"
          echo -e "\033[1;33m│\033[0m  \033[1;32mCtrl+Y\033[0m     Fuzzy find file (copy to clipboard)     \033[1;33m│\033[0m"
          echo -e "\033[1;33m│\033[0m  \033[1;32mCtrl+R\033[0m     Fuzzy search command history            \033[1;33m│\033[0m"
          echo -e "\033[1;33m╰──────────────────────────────────────────────────────╯\033[0m"
          echo ""
          echo -e "\033[1;35m╭──────────────────────────────────────────────────────╮\033[0m"
          echo -e "\033[1;35m│\033[0m \033[1;36m Hyprland Shortcuts\033[0m                                 \033[1;35m│\033[0m"
          echo -e "\033[1;35m├──────────────────────────────────────────────────────┤\033[0m"
          echo -e "\033[1;35m│\033[0m  \033[1;32mSuper+O\033[0m    Find files (rofi)                       \033[1;35m│\033[0m"
          echo -e "\033[1;35m│\033[0m  \033[1;32mSuper+G\033[0m    Search text in files (rofi+grep)        \033[1;35m│\033[0m"
          echo -e "\033[1;35m│\033[0m  \033[1;32mSuper+V\033[0m    Clipboard history                       \033[1;35m│\033[0m"
          echo -e "\033[1;35m│\033[0m  \033[1;32mSuper+P\033[0m    Screenshot menu                         \033[1;35m│\033[0m"
          echo -e "\033[1;35m│\033[0m  \033[1;32mSuper+Space\033[0m Application launcher (rofi)            \033[1;35m│\033[0m"
          echo -e "\033[1;35m│\033[0m  \033[1;32mSuper+L\033[0m    Window switcher (rofi)                  \033[1;35m│\033[0m"
          echo -e "\033[1;35m│\033[0m  \033[1;32mSuper+F\033[0m    File manager (Krusader)                 \033[1;35m│\033[0m"
          echo -e "\033[1;35m│\033[0m  \033[1;32mSuper+Return\033[0m Terminal (Ghostty)                    \033[1;35m│\033[0m"
          echo -e "\033[1;35m│\033[0m  \033[1;32mSuper+D\033[0m    Kill window                             \033[1;35m│\033[0m"
          echo -e "\033[1;35m│\033[0m  \033[1;32mSuper+Y\033[0m    Fullscreen                              \033[1;35m│\033[0m"
          echo -e "\033[1;35m│\033[0m  \033[1;32mSuper+A\033[0m    Toggle floating                         \033[1;35m│\033[0m"
          echo -e "\033[1;35m├──────────────────────────────────────────────────────┤\033[0m"
          echo -e "\033[1;35m│\033[0m  \033[1;34mSuper+C/T/S/R\033[0m  Move focus (BÉPO: left/down/up/right)\033[1;35m│\033[0m"
          echo -e "\033[1;35m│\033[0m  \033[1;34mSuper+Shift+C/T/S/R\033[0m  Move window                    \033[1;35m│\033[0m"
          echo -e "\033[1;35m│\033[0m  \033[1;34mSuper+\" « » ( ) @ +\033[0m  Workspaces 1-7                 \033[1;35m│\033[0m"
          echo -e "\033[1;35m╰──────────────────────────────────────────────────────╯\033[0m"
          echo ""
          echo -e "\033[1;32m╭──────────────────────────────────────────────────────╮\033[0m"
          echo -e "\033[1;32m│\033[0m \033[1;36m NixOS Commands\033[0m                                     \033[1;32m│\033[0m"
          echo -e "\033[1;32m├──────────────────────────────────────────────────────┤\033[0m"
          echo -e "\033[1;32m│\033[0m  \033[1;33mrebuild\033[0m    Rebuild NixOS configuration              \033[1;32m│\033[0m"
          echo -e "\033[1;32m│\033[0m  \033[1;33mupgrade\033[0m    Update flake and rebuild                 \033[1;32m│\033[0m"
          echo -e "\033[1;32m│\033[0m  \033[1;33mrollback\033[0m   Rollback to previous generation         \033[1;32m│\033[0m"
          echo -e "\033[1;32m│\033[0m  \033[1;33mgc\033[0m         Garbage collect old generations         \033[1;32m│\033[0m"
          echo -e "\033[1;32m╰──────────────────────────────────────────────────────╯\033[0m"
          echo ""
        }
        
        #=====================================================================
        # CUSTOM FZF FILE FINDER (Ctrl+F inserts file path)
        #=====================================================================
        __fzf_file_widget() {
          local selected
          selected=$(fd --type f --hidden --follow --exclude .git | fzf --height 40% --reverse)
          if [ -n "$selected" ]; then
            READLINE_LINE="''${READLINE_LINE:0:$READLINE_POINT}$selected''${READLINE_LINE:$READLINE_POINT}"
            READLINE_POINT=$((READLINE_POINT + ''${#selected}))
          fi
        }
        bind -x '"\C-f": __fzf_file_widget'

        # Ctrl+Y: Fuzzy find file and copy path to clipboard
        __fzf_copy_widget() {
          local selected
          selected=$(fd --type f --hidden --follow --exclude .git | fzf --height 40% --reverse)
          if [ -n "$selected" ]; then
            echo -n "$selected" | wl-copy
            echo "Copied: $selected"
          fi
        }
        bind -x '"\C-y": __fzf_copy_widget'

        # Ctrl+T: Fuzzy find file and cd to its parent directory
        __fzf_cd_widget() {
          local selected
          selected=$(fd --type f --hidden --follow --exclude .git | fzf --height 40% --reverse)
          if [ -n "$selected" ]; then
            local dir
            dir=$(dirname "$selected")
            cd "$dir" && echo "cd $dir"
          fi
        }
        bind -x '"\C-t": __fzf_cd_widget'

        #=====================================================================
        # BASH COMPLETION
        #=====================================================================
        if ! shopt -oq posix; then
          if [ -f /usr/share/bash-completion/bash_completion ]; then
            . /usr/share/bash-completion/bash_completion
          elif [ -f /etc/bash_completion ]; then
            . /etc/bash_completion
          fi
        fi
      '';
      
      # initExtra runs AFTER bashrcExtra - all custom fzf keybindings go here
      initExtra = ''
        # Set fzf default options with solarized colors
        export FZF_DEFAULT_OPTS="--height 40% --reverse --color=bg+:#073642,bg:#002b36,spinner:#2aa198,hl:#268bd2,fg:#839496,header:#268bd2,info:#b58900,pointer:#2aa198,marker:#2aa198,fg+:#eee8d5,prompt:#b58900,hl+:#268bd2"
        export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"

        # Ctrl+T: Fuzzy find file and cd to its parent directory
        __fzf_cd_to_file_dir() {
          local selected
          selected=$(fd --type f --hidden --follow --exclude .git | fzf)
          if [ -n "$selected" ]; then
            local dir
            dir=$(dirname "$selected")
            builtin cd "$dir"
            # Clear readline and force prompt refresh
            READLINE_LINE=""
            READLINE_POINT=0
            echo "cd $dir"
          fi
        }
        bind -x '"\\C-t": __fzf_cd_to_file_dir'

        # Ctrl+R: Fuzzy search command history
        __fzf_history_widget() {
          local selected
          selected=$(HISTTIMEFORMAT= history | fzf --tac --no-sort | sed 's/^[ ]*[0-9]*[ ]*//')
          if [ -n "$selected" ]; then
            READLINE_LINE="$selected"
            READLINE_POINT=''${#selected}
          fi
        }
        bind -x '"\\C-r": __fzf_history_widget'
      '';
      
      profileExtra = ''
        export EDITOR=emacs
        export BROWSER=brave
        
        if [ -d "$HOME/bin" ] ; then
          PATH="$HOME/bin:$PATH"
        fi
        
        if [ -d "$HOME/.cargo/bin" ] ; then
          PATH="$HOME/.cargo/bin:$PATH"
        fi
      '';
      
      sessionVariables = {
        EDITOR = "emacs";
        BROWSER = "brave";
        TERMINAL = "ghostty";
      };
      
      historySize = 10000;
      historyFileSize = 20000;
      historyControl = [ "ignoreboth" "erasedups" ];
      historyIgnore = [ "ls" "cd" "exit" ];
    };

    programs.autojump = {
      enable = true;
      enableBashIntegration = true;
    };

    programs.fzf = {
      enable = true;
      # Disable fzf's bash integration - we set up our own keybindings in initExtra
      enableBashIntegration = false;
      defaultCommand = "fd --type f --hidden --follow --exclude .git";
      changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
      colors = {
        "bg+" = "#073642";
        bg = "#002b36";
        spinner = "#2aa198";
        hl = "#268bd2";
        fg = "#839496";
        header = "#268bd2";
        info = "#b58900";
        pointer = "#2aa198";
        marker = "#2aa198";
        "fg+" = "#eee8d5";
        prompt = "#b58900";
        "hl+" = "#268bd2";
      };
    };

    programs.starship = {
      enable = true;
      enableBashIntegration = true;
      settings = {
        # Solarized Dark color palette
        palette = "solarized_dark";
        palettes.solarized_dark = {
          base03 = "#002b36";
          base02 = "#073642";
          base01 = "#586e75";
          base00 = "#657b83";
          base0 = "#839496";
          base1 = "#93a1a1";
          base2 = "#eee8d5";
          base3 = "#fdf6e3";
          yellow = "#b58900";
          orange = "#cb4b16";
          red = "#dc322f";
          magenta = "#d33682";
          violet = "#6c71c4";
          blue = "#268bd2";
          cyan = "#2aa198";
          green = "#859900";
        };

        # Two-line prompt format:
        # Line 1: Language versions, jobs, duration, status, time (info line)
        # Line 2: nix-shell, path, git info, $ (main prompt)
        format = "$rlang$python$rust$jobs$cmd_duration$status$time$line_break$nix_shell$directory$git_branch$git_status$character";

        character = {
          success_symbol = "[\\$](green)";
          error_symbol = "[\\$](red)";
        };

        username = {
          style_user = "green bold";
          style_root = "red bold";
          format = "[$user]($style)";
          show_always = true;
        };

        hostname = {
          ssh_only = false;
          format = "[@$hostname](base0):";
          disabled = false;
        };

        directory = {
          style = "blue bold";
          truncation_length = 100;  # Effectively show full path
          truncate_to_repo = false;  # Don't truncate, show full path
          fish_style_pwd_dir_length = 1;  # When truncating, use fish style (1 char per dir)
          truncation_symbol = "";
        };

        git_branch = {
          symbol = "";
          style = "green";
          format = " [($branch)]($style)";
        };

        git_status = {
          style = "red bold";
          format = "[$all_status$ahead_behind]($style)";
          conflicted = "=";
          ahead = "↑$count";
          behind = "↓$count";
          diverged = "↕";
          untracked = "?";
          stashed = "≡";
          modified = "*";
          staged = "+";
          renamed = "»";
          deleted = "✘";
        };

        nix_shell = {
          symbol = "";
          style = "red bold";
          format = "[nix-shell ]($style)";
        };

        # Command duration - shows when commands take > 2 seconds
        cmd_duration = {
          min_time = 2000;
          style = "yellow";
          format = " [$duration]($style)";
        };

        # Show current time
        time = {
          disabled = false;
          style = "base01";
          format = " [$time]($style)";
          time_format = "%H:%M";
        };

        # Show exit code on failure
        status = {
          disabled = false;
          style = "red";
          format = " [$status]($style)";
        };

        # Background jobs indicator
        jobs = {
          symbol = "⚙";
          style = "cyan";
          format = " [$symbol$number]($style)";
        };

        # Language detection modules
        rlang = {
          symbol = "R ";
          style = "blue";
          format = " [$symbol$version]($style)";
        };

        python = {
          symbol = "py ";
          style = "yellow";
          format = " [$symbol$version]($style)";
        };

        rust = {
          symbol = "rs ";
          style = "orange";
          format = " [$symbol$version]($style)";
        };

        # Disable modules we don't need
        aws.disabled = true;
        gcloud.disabled = true;
        kubernetes.disabled = true;
      };
    };

    #---------------------------------------------------------------------------
    # DEVELOPMENT ENVIRONMENT
    #---------------------------------------------------------------------------
    
    programs.emacs = {
      enable = true;
      package = pkgs.emacs-pgtk;
      extraPackages = epkgs: [ epkgs.vterm ];
    };

    services.emacs = {
      enable = true;
      client.enable = true;
    };

    #---------------------------------------------------------------------------
    # HYPRLAND WINDOW MANAGER
    #---------------------------------------------------------------------------
    
    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        "$mod" = "SUPER";
        
        monitor = ",preferred,auto,auto";

        exec-once = [
          "waybar"
          "nm-applet --indicator"   # Network manager applet (--indicator needed for tray)
          "wl-paste --watch cliphist store"
          "lxqt-policykit-agent"
        ];

        input = {
          kb_layout = "fr";
          kb_variant = "bepo";
          kb_options = "caps:escape";
          follow_mouse = 1;
          repeat_delay = 300;
          repeat_rate = 50;
          touchpad = {
            natural_scroll = false;
            disable_while_typing = true;
          };
        };

        general = {
          gaps_in = 2;
          gaps_out = 5;
          border_size = 1;
          "col.active_border" = "rgb(d33682)";
          "col.inactive_border" = "rgb(586e75)";
          layout = "master";
          allow_tearing = false;
        };

        animations = {
          enabled = true;
          bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
          animation = [
            "windows, 1, 7, myBezier"
            "windowsOut, 1, 7, default, popin 80%"
            "border, 1, 10, default"
            "borderangle, 1, 8, default"
            "fade, 1, 7, default"
            "workspaces, 1, 6, default"
          ];
        };

        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo = false;
          vfr = true;
        };

        bind = [
          "$mod, Return, exec, ghostty"
          "$mod, D, killactive"
          "$mod SHIFT, Q, exit"
          "$mod, F, exec, krusader"
          "$mod, Y, fullscreen, 1"
          "$mod, A, togglefloating"
          "$mod, Space, exec, rofi -show drun"
          "$mod, L, exec, rofi -show window"
          "$mod, P, exec, grimshot-menu"
          "$mod SHIFT, P, pseudo"
          "$mod, J, togglesplit"

          "$mod, V, exec, clipboard-menu"
          "$mod SHIFT, V, exec, clipboard-clear"

          # Fuzzy finders (fzf + rofi)
          "$mod, O, exec, rofi-files"
          "$mod, G, exec, rofi-grep"

          "$mod SHIFT, Return, layoutmsg, swapwithmaster master"

          # Window focus movement (BÉPO: C-T-S-R instead of H-J-K-L)
          "$mod, C, movefocus, l"
          "$mod, S, movefocus, u"
          "$mod, T, movefocus, d"
          "$mod, R, movefocus, r"

          "$mod SHIFT, C, movewindow, l"
          "$mod SHIFT, S, movewindow, u"
          "$mod SHIFT, T, movewindow, d"
          "$mod SHIFT, R, movewindow, r"

          # Workspace switching (BÉPO number row)
          "$mod, quotedbl, workspace, 1"
          "$mod, guillemotleft, workspace, 2"
          "$mod, guillemotright, workspace, 3"
          "$mod, parenleft, workspace, 4"
          "$mod, parenright, workspace, 5"
          "$mod, at, workspace, 6"
          "$mod, plus, workspace, 7"

          "$mod SHIFT, quotedbl, movetoworkspace, 1"
          "$mod SHIFT, guillemotleft, movetoworkspace, 2"
          "$mod SHIFT, guillemotright, movetoworkspace, 3"
          "$mod SHIFT, parenleft, movetoworkspace, 4"
          "$mod SHIFT, parenright, movetoworkspace, 5"
          "$mod SHIFT, at, movetoworkspace, 6"
          "$mod SHIFT, plus, movetoworkspace, 7"

          "$mod, grave, togglespecialworkspace, magic"
          "$mod SHIFT, grave, movetoworkspace, special:magic"

          "$mod, mouse_down, workspace, e+1"
          "$mod, mouse_up, workspace, e-1"
        ];

        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];

        bindl = [
          ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          # Brightness keys for MacBook
          ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
          ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ];

        windowrulev2 = [
          "suppressevent maximize, class:.*"

          "workspace 1, class:^(brave-browser)$"
          "noinitialfocus, class:^(brave-browser)$"
          "suppressevent activatefocus, class:^(brave-browser)$"

          "workspace 3, class:^(emacs)$"
          "noinitialfocus, class:^(emacs)$"
          "suppressevent activatefocus, class:^(emacs)$"

          "workspace 5, class:^(gimp-3.0)$"
          "noinitialfocus, class:^(gimp-3.0)$"
          "suppressevent activatefocus, class:^(gimp-3.0)$"
        ];
      };
    };

    #---------------------------------------------------------------------------
    # WAYBAR STATUS BAR
    #---------------------------------------------------------------------------
    
    programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          # Height matches the MacBook M2 notch area (~56px at native resolution)
          # Adjusted for your 1.5x scaling factor
          height = 28;
          spacing = 2;
          
          # Layout optimized for notch: content on sides, center is empty (notch area)
          modules-left = [ "hyprland/workspaces" ];
          modules-center = [];  # Empty - this is where the notch sits
          modules-right = [ "cpu" "memory" "battery" "wireplumber" "clock" "tray" "custom/power" ];

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
            format-icons = ["" "" "" "" ""];
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

    #---------------------------------------------------------------------------
    # APPLICATION CONFIGURATIONS
    #---------------------------------------------------------------------------
    
    programs.ghostty = {
      enable = true;
    
      themes.solarized-dark = {
        background = "002b36";
        foreground = "839496";
        cursor-color = "93a1a1";
        selection-background = "073642";
        selection-foreground = "eee8d5";
    
        palette = [
          "0=#073642"
          "1=#dc322f"
          "2=#859900"
          "3=#b58900"
          "4=#268bd2"
          "5=#d33682"
          "6=#2aa198"
          "7=#eee8d5"
          "8=#002b36"
          "9=#cb4b16"
          "10=#586e75"
          "11=#657b83"
          "12=#839496"
          "13=#6c71c4"
          "14=#93a1a1"
          "15=#fdf6e3"
        ];
      };
    
      settings = {
        theme = "solarized-dark";
        font-family = "Iosevka Custom";
        font-size = 16;
      };
    };

    programs.rofi = {
      enable = true;
      theme = "solarized_alternate";
    };


  programs.vim = {
    enable = true;
    settings = {
      number = true;
      relativenumber = false;
    };
    extraConfig = ''
      " BÉPO navigation (ctsr instead of hjkl)
      noremap c h
      noremap t j
      noremap s k
      noremap r l
  
      " Remap original functions
      noremap h c
      noremap j t
      noremap k s
      noremap l r
  
      " Capital versions
      noremap C H
      noremap T J
      noremap S K
      noremap R L
      noremap H C
      noremap J T
      noremap K S
      noremap L R
    '';
  };

  };

  #=============================================================================
  # SYSTEM VERSION
  #=============================================================================
  
  system.stateVersion = "25.11";
}
