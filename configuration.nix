#===============================================================================
# NixOS Configuration for Bruno's Hyprland Desktop
# Author: Bruno Rodrigues and Claude
# 
# This configuration provides a complete Wayland desktop environment with:
# - Hyprland window manager with BÉPO keyboard layout
# - Optional NVIDIA GPU support (via nvidia.nix if present)
# - Solarized Dark theme throughout
# - Development tools (Emacs, Git, direnv)
# - Modern applications (Brave, GIMP, etc.)
#
# Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').
#===============================================================================

{ config, pkgs, ... }:

{
  #=============================================================================
  # SYSTEM IMPORTS
  #=============================================================================
  
  imports = [
    ./cachix.nix                    # Binary cache configuration
    ./hardware-configuration.nix    # Hardware-specific settings
    <home-manager/nixos>            # Home Manager integration
  ] ++ (builtins.filter (f: builtins.pathExists f) [
    ./nvidia.nix                    # NVIDIA configuration (optional)
  ]);

  #=============================================================================
  # Garbage collection
  #=============================================================================

   nix.gc = {
     automatic = true;
     dates = "weekly";           # Run weekly
     options = "--delete-older-than 30d";  # Keep last 30 days
   };
   
   # Also clean up the Nix store automatically
   nix.settings.auto-optimise-store = true;

  #=============================================================================
  # Experimental features
  #=============================================================================

   nix.settings.experimental-features = [ "nix-command" "flakes" ];

  #=============================================================================
  # BOOT & KERNEL CONFIGURATION
  #=============================================================================
  
  boot = {
    # Use systemd-boot as the bootloader with EFI support
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    
    # Always use the latest kernel for best hardware support
    kernelPackages = pkgs.linuxPackages_latest;
  };

  #=============================================================================
  # GRAPHICS CONFIGURATION
  # Basic graphics stack (NVIDIA-specific parts in nvidia.nix)
  #=============================================================================
  
  # Enable modern graphics stack with 32-bit support for compatibility
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  #=============================================================================
  # Hardware
  #=============================================================================

  hardware.keyboard.zsa.enable = true;

  #=============================================================================
  # NETWORK & LOCALIZATION
  #=============================================================================

  networking = {
    hostName = "nixos";              # Machine hostname
    networkmanager.enable = true;    # Modern network management
  };

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
    variant = "bepo";  # Optimized French layout
  };
  
  console.keyMap = "fr";

  #=============================================================================
  # DISPLAY MANAGER & DESKTOP ENVIRONMENT
  #=============================================================================
  
  services = {
    # Enable X11 for compatibility (some apps still need it)
    xserver.enable = true;
    
    # SDDM display manager with Wayland support
    displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;        # Native Wayland support
      };
      defaultSession = "hyprland";   # Boot directly into Hyprland
      autoLogin = {
        enable = true;
        user = "brodrigues";
      };
    };
    
    # Enable Plasma 6 for applications that integrate well with it
    desktopManager.plasma6.enable = true;
  };

  #=============================================================================
  # TYPOGRAPHY & FONTS
  # High-quality fonts with proper rendering
  #=============================================================================
  
  fonts = {
    # Essential font packages
    packages = with pkgs; [
      liberation_ttf    # Metric-compatible with common fonts
      source-code-pro   # Excellent monospace font
      freetype         # Font rendering engine
      fontconfig       # Font configuration
    ];

    # Font rendering configuration for crisp text
    fontconfig = {
      enable = true;
      antialias = true;        # Smooth font edges
      cache32Bit = true;       # 32-bit application support
      
      # Optimize font rendering
      hinting = {
        enable = true;
        style = "slight";      # Light hinting for modern displays
      };
      subpixel.rgba = "rgb";   # Subpixel rendering
      
      # Default font preferences
      defaultFonts = {
        monospace = [ "Iosevka Custom" "Source Code Pro" ];
        sansSerif = [ "Liberation Sans" ];
        serif = [ "Liberation Serif" ];
      };
    };
  };

  #=============================================================================
  # AUDIO SYSTEM
  # Modern PipeWire setup replacing PulseAudio
  #=============================================================================
  
  # Disable legacy PulseAudio
  services.pulseaudio.enable = false;
  
  # Enable real-time kit for low-latency audio
  security.rtkit.enable = true;
  
  # PipeWire: Modern audio server with low latency
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;     # 32-bit application support
    };
    pulse.enable = true;       # PulseAudio compatibility layer
  };

  #=============================================================================
  # SYSTEM SERVICES
  #=============================================================================
  
  # Enable printing support
  services.printing = {
    enable = true;
    drivers = [ pkgs.samsung-unified-linux-driver ];
  };

  #=============================================================================
  # USER ACCOUNT CONFIGURATION
  #=============================================================================
  
  users.users.brodrigues = {
    isNormalUser = true;
    description = "Bruno Rodrigues";
    extraGroups = [ 
      "networkmanager"    # Network management permissions
      "wheel"            # Sudo access
    ];
    packages = with pkgs; [
      kdePackages.kate   # KDE text editor
    ];
   };

  #=============================================================================
  # PACKAGE MANAGEMENT & SYSTEM PACKAGES
  #=============================================================================
  
  # Allow proprietary software (needed for NVIDIA drivers, etc.)
  nixpkgs.config.allowUnfree = true;

  environment = {
    # Core system packages available to all users
    systemPackages = with pkgs; [

      #=============================================================================
      # Custom Script: nixpr-review (nix-shell for nixpkgs PR review)
      #=============================================================================
      (pkgs.writeShellScriptBin "nixpr-review" ''
        #!/usr/bin/env bash
      
        # Script to enter a nix-shell from a specific nixpkgs commit hash with chosen packages available.
        # Usage: ./nixpr-review.sh <commit-hash> <package-name1> [<package-name2> ...]
        # Example: ./nixpr-review.sh 3fae5e2 wget curl git
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
      
        # Download the nixpkgs tarball for the given commit hash if not already present
        if [ ! -d "$NIXPKGS_PATH" ]; then
            echo "Downloading nixpkgs at commit $COMMIT_HASH..."
            curl -L "$NIXPKGS_URL" -o "''${COMMIT_HASH}.tar.gz"
            tar -xzf "''${COMMIT_HASH}.tar.gz"
            rm "''${COMMIT_HASH}.tar.gz"
        fi
        nix-shell -I nixpkgs="./''${NIXPKGS_PATH}" -p "''${PACKAGES[@]}"
      '')

      # Development & AI Tools
      aider-chat                  # AI-powered coding assistant
      air-formatter               # Format R code
      vim                         # Text editor
      jq
      
      # Web & Communication
      brave                       # Privacy-focused browser
      
      # System Utilities
      cachix                      # Nix binary cache
      networkmanagerapplet        # Network management GUI
      pavucontrol                 # Audio control
      libnotify                   # To send notifications
      htop                        # System monitoring for popup
      btop                        # Better system monitoring
      krusader
      wget                        # File downloader
      lxqt.lxqt-policykit         # LXQT Policykit program
      tree
      ispell

      # Screen recording and video tools
      obs-studio                  # Wayland screen recorder
      ffmpeg-full                 # Full FFmpeg with all codecs
      kdePackages.kdenlive
      mpv
      vlc
      themechanger
      
      # Additional codecs and libraries
      x264                        # H.264 encoder
      x265                        # H.265/HEVC encoder
      libvpx                      # VP8/VP9 codecs
      
      # Wayland Tools
      cliphist
      grim                        # Needed for delayed area screenshot
      imv                         # Image viewer
      slurp                       # Screen area selection
      sway-contrib.grimshot       # Screenshot tool
      swww                        # Wallpaper manager
      waybar                      # Status bar
      hypridle                    # Screensaver
      wl-clipboard                # Clipboard utilities
      
      # Applications
      gimp3                       # Image editor
      kitty                       # Terminal emulator

      # Scripts to put in PATH
      (pkgs.writeShellScriptBin "grimshot-menu" ''
        #!/bin/sh
        
        # Screenshot options for rofi
        options="📺 Full Screen\n🖱️ Area Selection\n🪟 Current Window\n📋 Area to Clipboard\n📋 Screen to Clipboard\n📋 Window to Clipboard\n⏰ Screen (5s delay)\n⏰ Area (5s delay)"
        
        # Show rofi menu
        chosen=$(echo -e "$options" | rofi -dmenu -p "Screenshot" -i -theme-str '
          window { width: 400px; }
          listview { lines: 8; }
        ')
        
        # Create screenshots directory if it doesn't exist
        mkdir -p ~/Pictures/Screenshots
        
        # Generate filename with timestamp
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
                # First select the area, then wait
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

      # Clipboard menu with rofi
      (pkgs.writeShellScriptBin "clipboard-menu" ''
        #!/bin/sh
        
        # Check if cliphist has any content
        clips=$(cliphist list 2>/dev/null)
        
        if [ -z "$clips" ]; then
            # No history yet - show helpful options
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
        
        # Normal clipboard history menu
        clips=$(echo "$clips" | head -20 | cut -c1-100)
        
        chosen=$(echo "$clips" | rofi -dmenu -p "Clipboard History" -i \
            -theme-str 'window { width: 800px; } listview { lines: 15; }' \
            -theme-str 'element-text { font: "Iosevka Custom 11"; }')
        
        if [ -n "$chosen" ]; then
            echo "$chosen" | cliphist decode | wl-copy
            notify-send "Clipboard" "Item copied to clipboard" -t 2000
        fi
      '')
      
      # Optional: Script to clear clipboard history
      (pkgs.writeShellScriptBin "clipboard-clear" ''
        #!/bin/sh
        
        choice=$(echo -e "Yes\nNo" | rofi -dmenu -p "Clear clipboard history?" -i)
        
        if [ "$choice" = "Yes" ]; then
            cliphist wipe
            notify-send "Clipboard" "History cleared" -t 2000
        fi
      '')
    ];
    
    # Environment variables for optimal Wayland experience
    # (NVIDIA-specific variables are in nvidia.nix)
    sessionVariables = {
      QT_QPA_PLATFORMTHEME = "qtct";
      QT_QPA_PLATFORM = "wayland";
      GDK_SCALE = "1";         # or "2" for 200% scaling
      GDK_DPI_SCALE = "1.5";   # 1.5 for 150%, 1 for 100%
      QT_SCALE_FACTOR = "1.5"; # For Qt X11 apps, if you use any
      # Enable Wayland for Electron applications
      NIXOS_OZONE_WL = "1";
      XDG_SESSION_TYPE = "wayland";
    };
  };

  #=============================================================================
  # SYSTEM PROGRAMS & GLOBAL CONFIGURATION
  #=============================================================================
  
  programs = {
    # Hyprland window manager
    hyprland = {
      enable = true;
      xwayland.enable = true;    # X11 application compatibility
    };
    
    # Global Git configuration
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
    
    # Enable dconf for desktop applications
    dconf.enable = true;
  };

  #=============================================================================
  # HOME MANAGER CONFIGURATION
  # User-specific configurations and dotfiles
  #=============================================================================
  
  home-manager.users.brodrigues = { pkgs, ... }: {
    home.stateVersion = "25.05";

    qt = {
      enable = true;
      platformTheme.name = "qtct";
      style.name = "kvantum";
    };
    
    #---------------------------------------------------------------------------
    # Font scaling for xwayland apps
    #---------------------------------------------------------------------------
    xresources.properties = {
      "Xft.dpi" = "144"; # or "192" for 200% scaling, or "96" for 100% (adjust as needed)
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
            timeout = 300;                              # 5 minutes
            on-timeout = "hyprctl dispatch dpms off";   # screen off
            on-resume = "hyprctl dispatch dpms on";     # screen on
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
          frame_color = "#d33682";  # Solarized magenta
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
          background = "#002b36";  # Solarized base03
          foreground = "#839496";  # Solarized base0
          timeout = 10;
        };
    
        urgency_normal = {
          background = "#073642";  # Solarized base02
          foreground = "#839496";  # Solarized base0
          timeout = 10;
        };
    
        urgency_critical = {
          background = "#dc322f";  # Solarized red
          foreground = "#fdf6e3";  # Solarized base3
          frame_color = "#dc322f"; # Solarized red
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
    # Bash configuration with Solarized theme and productivity features
    #---------------------------------------------------------------------------
    programs.bash = {
      enable = true;
      
      # Useful command aliases
      shellAliases = {
        # Enhanced directory listings
        ll = "ls -alF";
        la = "ls -A";
        l = "ls -CF";
        ".." = "cd ..";
        "..." = "cd ../..";

        # Colorized grep commands
        grep = "grep --color=auto";
        fgrep = "fgrep --color=auto";
        egrep = "egrep --color=auto";
        
        # NixOS system management
        rebuild = "sudo nixos-rebuild switch";
        upgrade = "sudo nixos-rebuild switch --upgrade";
        rebuild-test = "sudo nixos-rebuild test";
        rebuild-dry = "sudo nixos-rebuild dry-build";
        
        # NVIDIA monitoring
        nvidia-info = "nvidia-smi";
        nvidia-settings = "nvidia-settings";
      };
      
      # Advanced bash configuration
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
        
        # Directory colors for ls command
        export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'
        
        # Solarized Dark color palette for prompt
        SOL_YELLOW="\[\033[38;5;136m\]"   # #b58900
        SOL_ORANGE="\[\033[38;5;166m\]"   # #cb4b16
        SOL_RED="\[\033[38;5;160m\]"      # #dc322f
        SOL_MAGENTA="\[\033[38;5;125m\]"  # #d33682
        SOL_VIOLET="\[\033[38;5;61m\]"    # #6c71c4
        SOL_BLUE="\[\033[38;5;33m\]"      # #268bd2
        SOL_CYAN="\[\033[38;5;37m\]"      # #2aa198
        SOL_GREEN="\[\033[38;5;64m\]"     # #859900
        SOL_BASE0="\[\033[38;5;244m\]"    # #839496
        RESET="\[\033[0m\]"
        
        #=====================================================================
        # INTELLIGENT GIT PROMPT
        # Shows branch, status, and remote tracking information
        #=====================================================================
        git_prompt_info() {
          local git_dir git_branch git_status
          
          # Check if we're in a git repository
          if git_dir=$(git rev-parse --git-dir 2>/dev/null); then
            # Get current branch or commit hash
            git_branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
            
            git_status=""
            
            # Check for various git states
            if ! git diff --quiet 2>/dev/null; then
              git_status+="*"  # Modified files
            fi
            
            if ! git diff --cached --quiet 2>/dev/null; then
              git_status+="+"  # Staged files
            fi
            
            if [ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
              git_status+="?"  # Untracked files
            fi
            
            # Check remote tracking status
            local ahead behind
            ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo "0")
            behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo "0")
            
            if [ "$ahead" -gt 0 ]; then
              git_status+="↑$ahead"
            fi
            
            if [ "$behind" -gt 0 ]; then
              git_status+="↓$behind"
            fi
            
            # Color coding based on repository state
            local git_color
            if [ -n "$git_status" ]; then
              git_color="$SOL_RED"    # Red for dirty repository
            else
              git_color="$SOL_GREEN"  # Green for clean repository
            fi
            
            echo -e " ''${git_color}(''${git_branch}''${git_status})$RESET"
          fi
        }
        
        #=====================================================================
        # DYNAMIC PROMPT GENERATION
        # Context-aware prompt that shows nix-shell status and git info
        #=====================================================================
        __prompt_command() {
          local git_info nix_prefix user_color host_color at_color
          git_info=$(git_prompt_info)
          
          # Detect nix-shell environment and adjust colors
          if [ -n "$IN_NIX_SHELL" ]; then
            nix_prefix="nix-shell "
            user_color="$SOL_RED"      # Red theme for nix-shell
            host_color="$SOL_RED"
            at_color="$SOL_RED"
          else
            nix_prefix=""
            user_color="$SOL_GREEN"    # Green theme for normal shell
            host_color="$SOL_GREEN"
            at_color="$SOL_BASE0"
          fi
          
          # Construct the dynamic prompt
          PS1="''${nix_prefix}''${user_color}\u''${at_color}@''${host_color}\h''${RESET}:''${SOL_BLUE}\w''${git_info}''${RESET}\$ "
        }

        # Set prompt command and initialize
        PROMPT_COMMAND="__prompt_command"
        __prompt_command
        
        #=====================================================================
        # UTILITY FUNCTIONS
        #=====================================================================
        
        # Create directory and navigate to it
        mkcd() {
          mkdir -p "$1" && cd "$1"
        }
        
        # Enhanced git status with colors
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
      
      # Profile configuration
      profileExtra = ''
        # Default applications
        export EDITOR=emacs
        export BROWSER=brave
        
        # Extend PATH with user directories
        if [ -d "$HOME/bin" ] ; then
          PATH="$HOME/bin:$PATH"
        fi
        
        if [ -d "$HOME/.cargo/bin" ] ; then
          PATH="$HOME/.cargo/bin:$PATH"
        fi
      '';
      
      # Session variables
      sessionVariables = {
        EDITOR = "emacs";
        BROWSER = "brave";
        TERMINAL = "kitty";
      };
      
      # History configuration
      historySize = 10000;
      historyFileSize = 20000;
      historyControl = [ "ignoreboth" "erasedups" ];
      historyIgnore = [ "ls" "cd" "exit" ];
    };

    # Smart directory jumping
    programs.autojump = {
      enable = true;
      enableBashIntegration = true;
    };

    #---------------------------------------------------------------------------
    # DEVELOPMENT ENVIRONMENT
    #---------------------------------------------------------------------------
    
    programs.emacs = {
      enable = true;
      package = pkgs.emacs-pgtk;  # Pure GTK build for Wayland
      extraPackages = epkgs: [ epkgs.vterm ];
    };

    # Enable the user service
    services.emacs = {
      enable = true;
      client.enable = true;
    };

    #---------------------------------------------------------------------------
    # HYPRLAND WINDOW MANAGER
    # Optimized for BÉPO keyboard layout and graphics
    #---------------------------------------------------------------------------
    
    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        # Modifier key for window manager shortcuts
        "$mod" = "SUPER";
        
        # Monitor configuration - auto-detect optimal settings
        monitor = ",preferred,auto,auto";

        # Applications to start with Hyprland
        exec-once = [
          "waybar"      # Status bar
          "nm-applet"   # Network manager applet
          "wl-paste --watch cliphist store"  # Handles both clipboard and primary selection
          "lxqt-policykit-agent"
        ];

        # Input configuration optimized for BÉPO layout
        input = {
          kb_layout = "fr";
          kb_variant = "bepo";
          follow_mouse = 1;
          repeat_delay = 300;
          repeat_rate = 50;
          touchpad.natural_scroll = false;
        };

        # Visual configuration with Solarized colors
        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
          "col.active_border" = "rgb(d33682)";    # Solarized magenta
          "col.inactive_border" = "rgb(586e75)";  # Solarized base01
          layout = "master";
          allow_tearing = false;
        };

        # Smooth animations
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

        # Miscellaneous settings
        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo = false;
          vfr = true;  # Variable refresh rate
        };

        # Key bindings optimized for BÉPO layout
        bind = [
          # Core application shortcuts
          "$mod, Return, exec, kitty"                    # Terminal
          "$mod, D, killactive"                          # Close window
          "$mod SHIFT, Q, exit"                          # Exit Hyprland
          "$mod, F, exec, krusader"                    # File manager
          "$mod, Y, fullscreen, 1"                       # Fullscreen
          "$mod, A, togglefloating"                      # Toggle floating
          "$mod, Space, exec, rofi -show drun"           # Application launcher
          "$mod, L, exec, rofi -show window"             # Window switcher
          "$mod, P, exec, grimshot-menu"                 # Screenshot menu
          "$mod SHIFT, P, pseudo"                        # Pseudo tiling
          "$mod, J, togglesplit"                         # Toggle split

          # Clipboard management
          "$mod, V, exec, clipboard-menu"           # Clipboard history menu
          "$mod SHIFT, V, exec, clipboard-clear"    # Clear clipboard history

          # Layout management
          "$mod SHIFT, Return, layoutmsg, swapwithmaster master"

          # Window focus movement (BÉPO: C-T-S-R instead of H-J-K-L)
          "$mod, C, movefocus, l"    # Left
          "$mod, S, movefocus, u"    # Up
          "$mod, T, movefocus, d"    # Down
          "$mod, R, movefocus, r"    # Right

          # Window movement (BÉPO layout)
          "$mod SHIFT, C, movewindow, l"
          "$mod SHIFT, S, movewindow, u"
          "$mod SHIFT, T, movewindow, d"
          "$mod SHIFT, R, movewindow, r"

          # Workspace switching (BÉPO number row: "«»()@+)
          "$mod, quotedbl, workspace, 1"        # "
          "$mod, guillemotleft, workspace, 2"   # «
          "$mod, guillemotright, workspace, 3"  # »
          "$mod, parenleft, workspace, 4"       # (
          "$mod, parenright, workspace, 5"      # )
          "$mod, at, workspace, 6"              # @
          "$mod, plus, workspace, 7"            # +

          # Move windows to workspace (BÉPO number row)
          "$mod SHIFT, quotedbl, movetoworkspace, 1"
          "$mod SHIFT, guillemotleft, movetoworkspace, 2"
          "$mod SHIFT, guillemotright, movetoworkspace, 3"
          "$mod SHIFT, parenleft, movetoworkspace, 4"
          "$mod SHIFT, parenright, movetoworkspace, 5"
          "$mod SHIFT, at, movetoworkspace, 6"
          "$mod SHIFT, plus, movetoworkspace, 7"

          # Special workspace (scratchpad)
          "$mod, grave, togglespecialworkspace, magic"
          "$mod SHIFT, grave, movetoworkspace, special:magic"

          # Workspace navigation with mouse
          "$mod, mouse_down, workspace, e+1"
          "$mod, mouse_up, workspace, e-1"
        ];

        # Mouse bindings
        bindm = [
          "$mod, mouse:272, movewindow"    # Move with left click
          "$mod, mouse:273, resizewindow"  # Resize with right click
        ];

        # Media key bindings
        bindl = [
          ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ];

        # Window rules for automatic workspace assignment
        windowrulev2 = [
          # Suppress maximize events (better for tiling)
          "suppressevent maximize, class:.*"

          # Application workspace assignments with focus prevention
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
    # System monitoring and controls with Solarized theme
    #---------------------------------------------------------------------------
    
    programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          # Bar positioning and layout
          layer = "top";
          position = "top";
          height = 40;
          spacing = 4;
          
          # Module arrangement
          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "clock" ];
          modules-right = [ "tray" "cpu" "memory" "wireplumber" "custom/power" ];

          # Workspace indicator
          "hyprland/workspaces" = {
            disable-scroll = true;
            all-outputs = true;
            format = "{name}";
          };

          # CPU monitoring with detailed tooltip
          cpu = {
            format = "{usage}%";
            tooltip-format = "Total: {usage}%\nCore 00: {usage0}%\nCore 01: {usage1}%\nCore 02: {usage2}%\nCore 03: {usage3}%\nCore 04: {usage4}%\nCore 05: {usage5}%\nCore 06: {usage6}%\nCore 07: {usage7}%\nCore 08: {usage8}%\nCore 09: {usage9}%\nCore 10: {usage10}%\nCore 11: {usage11}%";
            interval = 1;
            states = {
              warning = 70;
              critical = 90;
            };
          };

          # Memory monitoring
          memory = {
            format = " {used:0.1f}G/{total:0.1f}G";
            interval = 1;
            tooltip = true;
            tooltip-format = "Memory: {used:0.1f}G / {total:0.1f}G ({percentage}%)\nSwap: {swapUsed:0.1f}G / {swapTotal:0.1f}G\n\nClick to open htop for detailed process info";
            on-click = "kitty htop";
          };

          # Audio control
          wireplumber = {
            format = "Vol: {volume}%";
            format-muted = "Muted";
            scroll-step = 5;
            on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            on-click-right = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 100%";
            tooltip = true;
            tooltip-format = "{node_name}";
          };

          # Power menu
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

          # Clock with calendar
          clock = {
            timezone = "Europe/Luxembourg";
            format = "{:%Y-%m-%d %H:%M:%S}";
            interval = 1;
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

      # Solarized Dark theme for Waybar
      style = ''
        /*=====================================================================
         * WAYBAR SOLARIZED DARK THEME
         * Based on the Solarized Dark color palette
         *====================================================================*/
        
        * {
          font-family: "Iosevka Custom", monospace;
          font-size: 14px;
          border: none;
          border-radius: 0;
          min-height: 0;
        }

        /* Main bar styling */
        window#waybar {
          background-color: #002b36;        /* Solarized base03 */
          border-bottom: 3px solid #073642; /* Solarized base02 */
          color: #839496;                   /* Solarized base0 */
          transition-property: background-color;
          transition-duration: .5s;
        }

        /* Workspace buttons */
        #workspaces button {
          padding: 0 8px;
          background-color: transparent;
          color: #586e75;                   /* Solarized base01 */
          border: none;
          border-radius: 0;
        }

        #workspaces button:hover {
          background-color: #073642;        /* Solarized base02 */
          color: #839496;                   /* Solarized base0 */
        }

        #workspaces button.active {
          background-color: #d33682;        /* Solarized magenta */
          color: #fdf6e3;                   /* Solarized base3 */
          border-bottom: 3px solid #dc322f; /* Solarized red */
        }

        /* Module styling */
        #cpu, #memory, #clock, #wireplumber, #tray {
          padding: 0 10px;
          color: #839496;                   /* Solarized base0 */
          margin: 0 2px;
          font-size: 20px;
        }

        /* Individual module colors */
        #cpu {
          color: #268bd2;                   /* Solarized blue */
        }

        #memory {
          color: #859900;                   /* Solarized green */
        }

        #wireplumber {
          color: #cb4b16;                   /* Solarized orange */
        }

        #wireplumber.muted {
          color: #dc322f;                   /* Solarized red */
        }

        #clock {
          color: #b58900;                   /* Solarized yellow */
          font-weight: bold;
        }

        #custom-power {
          color: #dc322f;                   /* Solarized red */
          font-size: 20px;
          padding: 0 12px;
        }

        #tray {
          color: #6c71c4;                   /* Solarized violet */
        }

        /* Tooltip styling */
        tooltip {
          background-color: #073642;        /* Solarized base02 */
          color: #839496;                   /* Solarized base0 */
          border: 1px solid #586e75;       /* Solarized base01 */
          border-radius: 3px;
        }
      '';
    };

    #---------------------------------------------------------------------------
    # APPLICATION CONFIGURATIONS
    #---------------------------------------------------------------------------
    
    # Terminal emulator with Solarized theme
    programs.kitty = {
      enable = true;
      themeFile = "Solarized_Dark";
      settings = {
        font_family = "Iosevka Custom";
        font_size = 18;
      };
    };

    # Application launcher with Solarized theme
    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;  # Wayland-native version
      theme = "solarized_alternate";
    };
  };

  #=============================================================================
  # SYSTEM VERSION
  #=============================================================================
  
  system.stateVersion = "25.05";
}
