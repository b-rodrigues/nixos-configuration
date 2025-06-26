# NixOS Configuration
# Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, ... }:

{
  imports = [
    ./cachix.nix
    ./hardware-configuration.nix
    <home-manager/nixos>
  ];

  # ============================================================================
  # BOOT CONFIGURATION
  # ============================================================================
  
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };

  # ============================================================================
  # NETWORKING & LOCALIZATION
  # ============================================================================
  
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
  };

  time.timeZone = "Europe/Luxembourg";
  i18n.defaultLocale = "en_GB.UTF-8";

  # ============================================================================
  # INPUT & KEYBOARD CONFIGURATION
  # ============================================================================
  
  services.xserver.xkb = {
    layout = "fr";
    variant = "bepo";
  };
  
  console.keyMap = "fr";

  # ============================================================================
  # DISPLAY & DESKTOP ENVIRONMENT
  # ============================================================================
  
  services = {
    xserver.enable = true;
    displayManager = {
      sddm.enable = true;
      defaultSession = "plasma";
      autoLogin = {
        enable = true;
        user = "brodrigues";
      };
    };
    desktopManager.plasma6.enable = true;
  };

  # ============================================================================
  # FONTS CONFIGURATION
  # ============================================================================
  
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
      cache32Bit = true;
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

  # ============================================================================
  # AUDIO CONFIGURATION
  # ============================================================================
  
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
  };

  # ============================================================================
  # SERVICES
  # ============================================================================
  
  services.printing.enable = true;

  # ============================================================================
  # USER CONFIGURATION
  # ============================================================================
  
  users.users.brodrigues = {
    isNormalUser = true;
    description = "Bruno Rodrigues";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  # ============================================================================
  # NIXPKGS & PACKAGES
  # ============================================================================
  
  nixpkgs.config.allowUnfree = true;

  environment = {
    systemPackages = with pkgs; [
      brave
      cachix
      direnv
      dunst
      gimp3
      grim
      kitty
      krusader
      networkmanagerapplet
      pavucontrol
      slurp
      swww
      vim
      waybar
      wget
      wl-clipboard
    ];
    
    sessionVariables.NIXOS_OZONE_WL = "1";
  };

  # ============================================================================
  # PROGRAMS CONFIGURATION
  # ============================================================================
  
  programs = {
    bash.interactiveShellInit = ''eval "$(direnv hook bash)"'';
    
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    
    git = {
      enable = true;
      config = {
        user = {
          name = "Bruno Rodrigues";
          email = "bruno@brodrigues.co";
        };
      };
    };
    
    dconf.enable = true;
  };

  # ============================================================================
  # HOME MANAGER CONFIGURATION
  # ============================================================================
  
  home-manager.users.brodrigues = { pkgs, ... }: {
    home.stateVersion = "25.05";

    # --------------------------------------------------------------------------
    # SHELL CONFIGURATION
    # --------------------------------------------------------------------------
    
    programs.bash = {
      enable = true;
      
      shellAliases = {
        # Directory navigation
        ll = "ls -alF";
        la = "ls -A";
        l = "ls -CF";
        ".." = "cd ..";
        "..." = "cd ../..";
        
        # Grep with color
        grep = "grep --color=auto";
        fgrep = "fgrep --color=auto";
        egrep = "egrep --color=auto";
        
        # System aliases
        rebuild = "sudo nixos-rebuild switch";
        rebuild-test = "sudo nixos-rebuild test";
        rebuild-dry = "sudo nixos-rebuild dry-build";
      };
      
      bashrcExtra = ''
        # History settings
        export HISTSIZE=10000
        export HISTFILESIZE=20000
        export HISTCONTROL=ignoreboth:erasedups
        shopt -s histappend
        
        # Solarized Dark colors for ls
        export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'
        
        # Color definitions (Solarized Dark)
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
        
        # Function to get git branch and status
        git_prompt_info() {
          local git_dir git_branch git_status
          
          # Check if we're in a git repository
          if git_dir=$(git rev-parse --git-dir 2>/dev/null); then
            # Get current branch
            git_branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
            
            # Get git status
            git_status=""
            
            # Check for uncommitted changes
            if ! git diff --quiet 2>/dev/null; then
              git_status+="*"  # Modified files
            fi
            
            # Check for staged changes
            if ! git diff --cached --quiet 2>/dev/null; then
              git_status+="+"  # Staged files
            fi
            
            # Check for untracked files
            if [ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
              git_status+="?"  # Untracked files
            fi
            
            # Check if we're ahead/behind remote
            local ahead behind
            ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo "0")
            behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo "0")
            
            if [ "$ahead" -gt 0 ]; then
              git_status+="↑$ahead"
            fi
            
            if [ "$behind" -gt 0 ]; then
              git_status+="↓$behind"
            fi
            
            # Format the git info
            local git_color
            if [ -n "$git_status" ]; then
              git_color="$SOL_RED"  # Red if there are changes
            else
              git_color="$SOL_GREEN"  # Green if clean
            fi
            
            echo -e " ''${git_color}(''${git_branch}''${git_status})$RESET"
          fi
        }
        
        # Function to set the prompt - this will be called before every prompt
        __prompt_command() {
          local git_info nix_prefix
          git_info=$(git_prompt_info)
          
          # Check if we're in a nix-shell and prepend if so
          if [ -n "$IN_NIX_SHELL" ]; then
            nix_prefix="nix-shell "
          else
            nix_prefix=""
          fi
          
          # Set the prompt
          PS1="''${nix_prefix}''${SOL_GREEN}\u''${SOL_BASE0}@''${SOL_GREEN}\h''${RESET}:''${SOL_BLUE}\w''${git_info}''${RESET}\$ "
        }
        
        # Set PROMPT_COMMAND to update prompt before every command
        PROMPT_COMMAND="__prompt_command"
        
        # Also set it immediately for the current session
        __prompt_command
        
        # Custom functions
        mkcd() {
          mkdir -p "$1" && cd "$1"
        }
        
        # Function to show git status with colors
        gst() {
          git status --short --branch
        }
        
        # Enable programmable completion features
        if ! shopt -oq posix; then
          if [ -f /usr/share/bash-completion/bash_completion ]; then
            . /usr/share/bash-completion/bash_completion
          elif [ -f /etc/bash_completion ]; then
            . /etc/bash_completion
          fi
        fi
      '';
      
      profileExtra = ''
        export EDITOR=vim
        export BROWSER=brave
        
        # Add personal bin directory to PATH if it exists
        if [ -d "$HOME/bin" ] ; then
          PATH="$HOME/bin:$PATH"
        fi
        
        # Add cargo bin if it exists (for Rust)
        if [ -d "$HOME/.cargo/bin" ] ; then
          PATH="$HOME/.cargo/bin:$PATH"
        fi
      '';
      
      sessionVariables = {
        EDITOR = "vim";
        BROWSER = "brave";
        TERMINAL = "kitty";
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

    # --------------------------------------------------------------------------
    # DEVELOPMENT TOOLS
    # --------------------------------------------------------------------------
    
    programs.emacs = {
      enable = true;
      package = pkgs.emacs-pgtk;
    };

    # --------------------------------------------------------------------------
    # WINDOW MANAGER CONFIGURATION
    # --------------------------------------------------------------------------
    
    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        "$mod" = "SUPER";
        monitor = ",preferred,auto,auto";

        exec-once = [
          "waybar"
          "nm-applet"
        ];

        input = {
          kb_layout = "fr";
          kb_variant = "bepo";
          follow_mouse = 1;
          repeat_delay = 300;
          repeat_rate = 50;
          touchpad.natural_scroll = false;
        };

        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
          "col.active_border" = "rgb(d33682)";    # Solarized magenta
          "col.inactive_border" = "rgb(586e75)";  # Solarized base01
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
        };

        bind = [
          # Application shortcuts
          "$mod, Return, exec, kitty"
          "$mod, D, killactive"
          "$mod SHIFT, Q, exit"
          "$mod, F, exec, krusader"
          "$mod, Y, fullscreen, 1"
          "$mod, A, togglefloating"
          "$mod, Space, exec, rofi -show drun"
          "$mod, L, exec, rofi -show window"
          "$mod, P, pseudo"
          "$mod, J, togglesplit"

          # Layout management
          "$mod SHIFT, Return, layoutmsg, swapwithmaster master"

          # Focus movement (BÉPO layout)
          "$mod, C, movefocus, l"
          "$mod, S, movefocus, u"
          "$mod, T, movefocus, d"
          "$mod, R, movefocus, r"

          # Window movement (BÉPO layout)
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

          # Move window to workspace (BÉPO number row)
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

          # Workspace navigation
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
        ];

        windowrulev2 = [
          "suppressevent maximize, class:.*"

          # Application workspace assignments with focus prevention
          "workspace 1, class:^(brave-browser)$"
          "noinitialfocus, class:^(brave-browser)$"
          "suppressevent activatefocus, class:^(brave-browser)$"

          "workspace 3, class:^(Emacs)$"
          "noinitialfocus, class:^(Emacs)$"
          "suppressevent activatefocus, class:^(Emacs)$"

          "workspace 5, class:^(gimp-3.0)$"
          "noinitialfocus, class:^(gimp-3.0)$"
          "suppressevent activatefocus, class:^(gimp-3.0)$"
        ];
      };
    };

    # --------------------------------------------------------------------------
    # WAYBAR CONFIGURATION
    # --------------------------------------------------------------------------
    
    programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 40;
          spacing = 4;
          
          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "clock" ];
          modules-right = [ "tray" "cpu" "memory" "wireplumber" "custom/power" ];

          "hyprland/workspaces" = {
            disable-scroll = true;
            all-outputs = true;
            format = "{name}";
          };

          cpu = {
            format = " {usage}%";
            tooltip = false;
            interval = 1;
          };

          memory = {
            format = " {used:0.1f}G/{total:0.1f}G";
            interval = 1;
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

          # Power menu module
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
          color: #dc322f;  /* Solarized red for power button */
          font-size: 20px;  /* Increased from 16px to 20px */
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

    # --------------------------------------------------------------------------
    # APPLICATION CONFIGURATIONS
    # --------------------------------------------------------------------------
    
    programs.kitty = {
      enable = true;
      themeFile = "Solarized_Dark";
      settings = {
        font_family = "Iosevka Custom";
        font_size = 18;
      };
    };

    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      theme = {
        "*" = {
          background-color = "#002b36";
          foreground-color = "#839496";
          border-color = "#d33682";
          separatorcolor = "#073642";
          selected-normal-foreground = "#fdf6e3";
          selected-normal-background = "#d33682";
        };
      };
    };
  };

  # ============================================================================
  # SYSTEM STATE VERSION
  # ============================================================================
  
  system.stateVersion = "25.05";
}