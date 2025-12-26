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
    ];
    
    sessionVariables = {
      QT_QPA_PLATFORMTHEME = "qtct";
      QT_QPA_PLATFORM = "wayland";
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
      platformTheme.name = "qtct";
      style.name = "kvantum";
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
        # SOLARIZED DARK COLOR SCHEME
        #=====================================================================
        
        export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'
        
        SOL_YELLOW="\[\033[38;5;136m\]"
        SOL_ORANGE="\[\033[38;5;166m\]"
        SOL_RED="\[\033[38;5;160m\]"
        SOL_MAGENTA="\[\033[38;5;125m\]"
        SOL_VIOLET="\[\033[38;5;61m\]"
        SOL_BLUE="\[\033[38;5;33m\]"
        SOL_CYAN="\[\033[38;5;37m\]"
        SOL_GREEN="\[\033[38;5;64m\]"
        SOL_BASE0="\[\033[38;5;244m\]"
        RESET="\[\033[0m\]"
        
        #=====================================================================
        # INTELLIGENT GIT PROMPT
        #=====================================================================
        git_prompt_info() {
          local git_dir git_branch git_status
          
          if git_dir=$(git rev-parse --git-dir 2>/dev/null); then
            git_branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
            
            git_status=""
            
            if ! git diff --quiet 2>/dev/null; then
              git_status+="*"
            fi
            
            if ! git diff --cached --quiet 2>/dev/null; then
              git_status+="+"
            fi
            
            if [ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
              git_status+="?"
            fi
            
            local ahead behind
            ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo "0")
            behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo "0")
            
            if [ "$ahead" -gt 0 ]; then
              git_status+="↑$ahead"
            fi
            
            if [ "$behind" -gt 0 ]; then
              git_status+="↓$behind"
            fi
            
            local git_color
            if [ -n "$git_status" ]; then
              git_color="$SOL_RED"
            else
              git_color="$SOL_GREEN"
            fi
            
            echo -e " ''${git_color}(''${git_branch}''${git_status})$RESET"
          fi
        }
        
        #=====================================================================
        # DYNAMIC PROMPT GENERATION
        #=====================================================================
        __prompt_command() {
          local git_info nix_prefix user_color host_color at_color
          git_info=$(git_prompt_info)
          
          if [ -n "$IN_NIX_SHELL" ]; then
            nix_prefix="nix-shell "
            user_color="$SOL_RED"
            host_color="$SOL_RED"
            at_color="$SOL_RED"
          else
            nix_prefix=""
            user_color="$SOL_GREEN"
            host_color="$SOL_GREEN"
            at_color="$SOL_BASE0"
          fi
          
          PS1="''${nix_prefix}''${user_color}\u''${at_color}@''${host_color}\h''${RESET}:''${SOL_BLUE}\w''${git_info}''${RESET}\$ "
        }

        PROMPT_COMMAND="__prompt_command"
        __prompt_command
        
        #=====================================================================
        # UTILITY FUNCTIONS
        #=====================================================================
        
        mkcd() {
          mkdir -p "$1" && cd "$1"
        }
        
        gst() {
          git status --short --branch
        }
        
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
          "nm-applet"   # Network manager applet
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
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
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
          height = 40;
          spacing = 4;
          
          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ ];
          modules-right = [ "tray" "cpu" "memory" "battery" "wireplumber" "clock" "custom/power" ];

          "hyprland/workspaces" = {
            disable-scroll = true;
            all-outputs = true;
            format = "{name}";
          };

          cpu = {
            format = "{usage}%";
            tooltip-format = "CPU: {usage}%";
            interval = 1;
            states = {
              warning = 70;
              critical = 90;
            };
          };

          memory = {
            format = " {used:0.1f}G/{total:0.1f}G";
            interval = 1;
            tooltip = true;
            tooltip-format = "Memory: {used:0.1f}G / {total:0.1f}G ({percentage}%)";
            on-click = "ghostty htop";
          };

          battery = {
            format = "{icon} {capacity}%";
            format-icons = ["" "" "" "" ""];
            format-charging = "⚡ {capacity}%";
            states = {
              warning = 30;
              critical = 15;
            };
          };

          wireplumber = {
            format = "Vol: {volume}%";
            format-muted = "Muted";
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
            format = "{:%d-%m\n%H:%M}";
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
          font-size: 14px;
          border: none;
          border-radius: 0;
          min-height: 0;
        }

        window#waybar {
          background-color: #002b36;
          border-bottom: 3px solid #073642;
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
          border-bottom: 3px solid #dc322f;
        }

        #cpu, #memory, #clock, #wireplumber, #tray, #battery {
          padding: 0 10px;
          color: #839496;
          margin: 0 2px;
          font-size: 20px;
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
          font-size: 11px;
          line-height: 1.2;
        }

        #custom-power {
          color: #dc322f;
          font-size: 20px;
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
