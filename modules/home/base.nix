#===============================================================================
# Shared home-manager configuration (user brodrigues)
#
# Everything below applies identically to both hosts. Platform-specific
# home-manager entries (waybar layout, per-host aliases) live in
# modules/desktop and modules/apple-silicon; nothing here references them.
#===============================================================================

{ pkgs, ... }:
{
  home-manager.users.brodrigues =
    { pkgs, ... }:
    {
      # home.stateVersion is set in platform-specific modules

      qt = {
        enable = true;
        platformTheme.name = "kde";
        style.name = "breeze";
      };

      # Install Breeze themes and icons for Qt apps
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
          DecorationFocus=211,54,130
          DecorationHover=211,54,130
          ForegroundActive=211,54,130
          ForegroundInactive=88,110,117
          ForegroundLink=211,54,130
          ForegroundNegative=220,50,47
          ForegroundNeutral=203,75,22
          ForegroundNormal=131,148,150
          ForegroundPositive=133,153,0
          ForegroundVisited=108,113,196

          [Colors:Complementary]
          BackgroundAlternate=0,43,54
          BackgroundNormal=7,54,66
          DecorationFocus=211,54,130
          DecorationHover=211,54,130
          ForegroundActive=211,54,130
          ForegroundInactive=88,110,117
          ForegroundLink=211,54,130
          ForegroundNegative=220,50,47
          ForegroundNeutral=203,75,22
          ForegroundNormal=131,148,150
          ForegroundPositive=133,153,0
          ForegroundVisited=108,113,196

          [Colors:Header]
          BackgroundAlternate=7,54,66
          BackgroundNormal=7,54,66
          DecorationFocus=211,54,130
          DecorationHover=211,54,130
          ForegroundActive=211,54,130
          ForegroundInactive=88,110,117
          ForegroundLink=211,54,130
          ForegroundNegative=220,50,47
          ForegroundNeutral=203,75,22
          ForegroundNormal=131,148,150
          ForegroundPositive=133,153,0
          ForegroundVisited=108,113,196

          [Colors:Header][Inactive]
          BackgroundAlternate=7,54,66
          BackgroundNormal=7,54,66
          DecorationFocus=211,54,130
          DecorationHover=211,54,130
          ForegroundActive=211,54,130
          ForegroundInactive=88,110,117
          ForegroundLink=211,54,130
          ForegroundNegative=220,50,47
          ForegroundNeutral=203,75,22
          ForegroundNormal=131,148,150
          ForegroundPositive=133,153,0
          ForegroundVisited=108,113,196

          [Colors:Selection]
          BackgroundAlternate=0,43,54
          BackgroundNormal=211,54,130
          DecorationFocus=211,54,130
          DecorationHover=211,54,130
          ForegroundActive=0,0,0
          ForegroundInactive=88,110,117
          ForegroundLink=0,0,0
          ForegroundNegative=220,50,47
          ForegroundNeutral=203,75,22
          ForegroundNormal=0,0,0
          ForegroundPositive=133,153,0
          ForegroundVisited=108,113,196

          [Colors:Tooltip]
          BackgroundAlternate=7,54,66
          BackgroundNormal=7,54,66
          DecorationFocus=211,54,130
          DecorationHover=211,54,130
          ForegroundActive=211,54,130
          ForegroundInactive=88,110,117
          ForegroundLink=211,54,130
          ForegroundNegative=220,50,47
          ForegroundNeutral=203,75,22
          ForegroundNormal=131,148,150
          ForegroundPositive=133,153,0
          ForegroundVisited=108,113,196

          [Colors:View]
          BackgroundAlternate=7,54,66
          BackgroundNormal=0,43,54
          DecorationFocus=211,54,130
          DecorationHover=211,54,130
          ForegroundActive=211,54,130
          ForegroundInactive=88,110,117
          ForegroundLink=211,54,130
          ForegroundNegative=220,50,47
          ForegroundNeutral=203,75,22
          ForegroundNormal=131,148,150
          ForegroundPositive=133,153,0
          ForegroundVisited=108,113,196

          [Colors:Window]
          BackgroundAlternate=7,54,66
          BackgroundNormal=7,54,66
          DecorationFocus=211,54,130
          DecorationHover=211,54,130
          ForegroundActive=211,54,130
          ForegroundInactive=88,110,117
          ForegroundLink=211,54,130
          ForegroundNegative=220,50,47
          ForegroundNeutral=203,75,22
          ForegroundNormal=131,148,150
          ForegroundPositive=133,153,0
          ForegroundVisited=108,113,196

          [General]
          ColorScheme=SolarizedDark
          Name=Breeze Solarized Dark
          shadeSortColumn=true

          [Icons]
          Theme=Papirus-Dark
          Panel=22
          Desktop=32
          Dialog=22
          MainToolbar=16
          Small=16
          Toolbar=16

          [KDE]
          contrast=4
          ShowDeleteCommand=false
          SingleClick=false

          [Toolbar style]
          ToolButtonStyle=IconOnly
          ToolButtonStyleOtherToolbars=IconOnly

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

          # NixOS system management - Platform-agnostic using hostname
          rebuild = "sudo nixos-rebuild switch --flake /home/brodrigues/Documents/repos/nixos-configuration#$(hostname)";
          upgrade = "cd /home/brodrigues/Documents/repos/nixos-configuration && nix flake update && sudo nixos-rebuild switch --flake .#$(hostname)";
          rebuild-test = "sudo nixos-rebuild test --flake /home/brodrigues/Documents/repos/nixos-configuration#$(hostname)";
          rebuild-dry = "sudo nixos-rebuild dry-build --flake /home/brodrigues/Documents/repos/nixos-configuration#$(hostname)";
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
            echo -e "\033[1;33m│\033[0m  \033[1;32mCtrl+G\033[0m     Fuzzy find file, insert cd command      \033[1;33m│\033[0m"
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
          bind -x '"\\C-f": __fzf_file_widget'

          # Ctrl+Y: Fuzzy find file and copy path to clipboard
          __fzf_copy_widget() {
            local selected
            selected=$(fd --type f --hidden --follow --exclude .git | fzf --height 40% --reverse)
            if [ -n "$selected" ]; then
              echo -n "$selected" | wl-copy
              echo "Copied: $selected"
            fi
          }
          bind -x '"\\C-y": __fzf_copy_widget'


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

          # Ctrl+G: Fuzzy find file and insert cd command to its parent directory
          __fzf_cd_to_file_dir() {
            local selected
            selected=$(fd --type f --hidden --follow --exclude .git | fzf)
            if [ -n "$selected" ]; then
              local dir
              dir=$(dirname "$selected")
              READLINE_LINE="cd \"$dir\""
              READLINE_POINT=''${#READLINE_LINE}
            fi
          }
          bind -x '"\\C-g": __fzf_cd_to_file_dir'

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
        historyControl = [
          "ignoreboth"
          "erasedups"
        ];
        historyIgnore = [
          "ls"
          "cd"
          "exit"
        ];
      };

      programs.autojump = {
        enable = true;
        enableBashIntegration = true;
      };

      programs.tmux = {
        enable = true;
        clock24 = true;
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

          format = "$username$hostname$rlang$python$rust$jobs$cmd_duration$status$time$line_break$nix_shell$directory$git_branch$git_status$character";

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
            truncation_length = 100;
            truncate_to_repo = false;
            fish_style_pwd_dir_length = 1;
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

          cmd_duration = {
            min_time = 2000;
            style = "yellow";
            format = " [$duration]($style)";
          };

          time = {
            disabled = false;
            style = "base01";
            format = " [$time]($style)";
            time_format = "%H:%M";
          };

          status = {
            disabled = false;
            style = "red";
            format = " [$status]($style)";
          };

          jobs = {
            symbol = "⚙";
            style = "cyan";
            format = " [$symbol$number]($style)";
          };

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
      # HYPRLAND WINDOW MANAGER - Base config (waybar and touchpad in platform modules)
      #---------------------------------------------------------------------------

      wayland.windowManager.hyprland = {
        enable = true;
        configType = "hyprlang";
        settings = {
          "$mod" = "SUPER";

          monitor = ",preferred,auto,auto";

          exec-once = [
            "awww-daemon & sleep 1 && awww clear 073642"
            "waybar"
            "nm-applet --indicator"
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
            gaps_in = 0;
            gaps_out = 0;
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
              "windows, 1, 3, myBezier"
              "windowsOut, 1, 3, default, popin 80%"
              "border, 1, 4, default"
              "borderangle, 1, 3, default"
              "fade, 1, 3, default"
              "workspaces, 1, 2, default"
            ];
          };

          misc = {
            force_default_wallpaper = 0;
            disable_hyprland_logo = true;
            vrr = 0;
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

            "$mod, V, exec, clipboard-menu"
            "$mod SHIFT, V, exec, clipboard-clear"

            "$mod, O, exec, rofi-files"
            "$mod, G, exec, rofi-grep"

            "$mod SHIFT, Return, layoutmsg, swapwithmaster master"

            "$mod, C, movefocus, l"
            "$mod, S, movefocus, u"
            "$mod, T, movefocus, d"
            "$mod, R, movefocus, r"

            "$mod SHIFT, C, movewindow, l"
            "$mod SHIFT, S, movewindow, u"
            "$mod SHIFT, T, movewindow, d"
            "$mod SHIFT, R, movewindow, r"

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
            ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
            ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
          ];

          windowrule = [
            "suppress_event maximize, match:class .*"

            "workspace 1 silent, match:class ^(brave-browser)$"
            "no_initial_focus 1, match:class ^(brave-browser)$"
            "suppress_event activatefocus, match:class ^(brave-browser)$"

            "workspace 3 silent, match:class ^(emacs)$"
            "no_initial_focus 1, match:class ^(emacs)$"
            "suppress_event activatefocus, match:class ^(emacs)$"

            "workspace 5 silent, match:class ^(gimp-3.0)$"
            "no_initial_focus 1, match:class ^(gimp-3.0)$"
            "suppress_event activatefocus, match:class ^(gimp-3.0)$"
          ];
        };
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

}
