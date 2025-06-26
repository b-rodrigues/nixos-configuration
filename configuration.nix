# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./cachix.nix
      ./hardware-configuration.nix
      <home-manager/nixos>
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Luxembourg";
  i18n.defaultLocale = "en_GB.UTF-8";

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.displayManager.defaultSession = "plasma";

  services.xserver.xkb = {
    layout = "fr";
    variant = "bepo";
  };

  fonts = {
    packages = with pkgs; [
      # Essential fonts
      liberation_ttf
      source-code-pro
      
      # Better font rendering
      freetype
      fontconfig
      
    ];

    fontconfig = {
      enable = true;
      antialias = true;
      cache32Bit = true;
      hinting.enable = true;
      hinting.style = "slight";
      subpixel.rgba = "rgb";
      
      defaultFonts = {
        monospace = [ "Iosevka Custom" "Source Code Pro" ];
        sansSerif = [ "Liberation Sans" ];
        serif = [ "Liberation Serif" ];
      };
    };
  };

  console.keyMap = "fr";

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.brodrigues = {
    isNormalUser = true;
    description = "Bruno Rodrigues";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "brodrigues";

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    brave
    cachix
    direnv
    dunst
    gimp3
    grim
    kitty
    krusader
    rofi-wayland
    slurp
    swww
    vim
    waybar
    wget
    wl-clipboard
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  programs.bash.interactiveShellInit = ''eval "$(direnv hook bash)"'';

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  programs.git = {
    enable = true;
    config = {
      user = {
        name = "Bruno Rodrigues";
        email = "bruno@brodrigues.co";
      };
    };
  };

  programs.dconf.enable = true;

  home-manager.users.brodrigues = { pkgs, ... }: {
    home.stateVersion = "25.05";

    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        "$mod" = "SUPER";

        monitor = ",preferred,auto,auto";

        exec-once = [
          "waybar"
        ];

        input = {
          kb_layout = "fr";
          kb_variant = "bepo";
          follow_mouse = 1;
          repeat_delay = 300;
          repeat_rate = 50;
          touchpad = {
            natural_scroll = false;
          };
        };

        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
          "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
          "col.inactive_border" = "rgba(595959aa)";
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
          # Terminal and basic apps
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

          "$mod SHIFT, Return, layoutmsg, swapwithmaster master"

          "$mod, C, movefocus, l"
          "$mod, S, movefocus, u"
          "$mod, T, movefocus, d"
          "$mod, R, movefocus, r"

          # Move windows with B�PO layout
          "$mod SHIFT, C, movewindow, l"
          "$mod SHIFT, S, movewindow, u"
          "$mod SHIFT, T, movewindow, d"
          "$mod SHIFT, R, movewindow, r"

          # Switch workspaces with B�PO number row
          "$mod, quotedbl, workspace, 1"      # " key (1 on B�PO)
          "$mod, guillemotleft, workspace, 2"  # � key (2 on B�PO)
          "$mod, guillemotright, workspace, 3" # � key (3 on B�PO)
          "$mod, parenleft, workspace, 4"              # ( key (4 on B�PO)
          "$mod, parenright, workspace, 5"              # ) key (5 on B�PO)
          "$mod, at, workspace, 6"             # @ key (6 on B�PO)
          "$mod, plus, workspace, 7"           # + key (7 on B�PO)

          # Move active window to workspace
          "$mod SHIFT, quotedbl, movetoworkspace, 1"
          "$mod SHIFT, guillemotleft, movetoworkspace, 2"
          "$mod SHIFT, guillemotright, movetoworkspace, 3"
          "$mod SHIFT, parenleft, movetoworkspace, 4"
          "$mod SHIFT, parenright, movetoworkspace, 5"
          "$mod SHIFT, at, movetoworkspace, 6"
          "$mod SHIFT, plus, movetoworkspace, 7"

          # Example special workspace (scratchpad)
          "$mod, grave, togglespecialworkspace, magic"
          "$mod SHIFT, grave, movetoworkspace, special:magic"

          # Scroll through existing workspaces
          "$mod, mouse_down, workspace, e+1"
          "$mod, mouse_up, workspace, e-1"
        ];

        bindm = [
          # Move/resize windows with mouse
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];

        # Audio controls (if you have media keys)
        bindl = [
          ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ];

        windowrulev2 = [
          "suppressevent maximize, class:.*"

          # Keep the workspace rule but add focus prevention
          "workspace 1, class:^(brave-browser)$"
          "noinitialfocus, class:^(brave-browser)$"
          "suppressevent activatefocus, class:^(brave-browser)$"

          # Keep the workspace rule but add focus prevention
          "workspace 3, class:^(Emacs)$"
          "noinitialfocus, class:^(Emacs)$"
          "suppressevent activatefocus, class:^(Emacs)$"

          # Keep the workspace rule but add focus prevention
          "workspace 5, class:^(gimp-3.0)$"
          "noinitialfocus, class:^(gimp-3.0)$"
          "suppressevent activatefocus, class:^(gimp-3.0)$"

        ];

      };
    };

    programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 30;
          spacing = 4;
          
          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "clock" ];
          modules-right = [ "tray" "cpu" "memory" ];

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

          clock = {
            timezone = "Europe/Luxembourg";
            format = "{:%Y-%m-%d %H:%M:%S}";
            interval = 1;
            on-click = "show-calendar";
            tooltip-format = "<span>{calendar}</span>";
            calendar = {
              mode = "month";
              format = {
                months = "<span color='#ff6699'><b>{}</b></span>";
                days = "<span color='#cdd6f4'><b>{}</b></span>";
                weekdays = "<span color='#7CD37C'><b>{}</b></span>";
                today = "<span color='#ffcc66'><b>{}</b></span>";
              };
            };
          };
         };
        };

      style = ''
        * {
          font-family: "Source Code Pro", monospace;
          font-size: 14px;
        }

        window#waybar {
          background-color: rgba(43, 48, 59, 0.8);
          border-bottom: 3px solid rgba(100, 114, 125, 0.5);
          color: #ffffff;
          transition-property: background-color;
          transition-duration: .5s;
        }

        #workspaces button {
          padding: 0 5px;
          background-color: transparent;
          color: #ffffff;
          border: none;
          border-radius: 0;
        }

        #workspaces button:hover {
          background: rgba(0, 0, 0, 0.2);
        }

        #workspaces button.active {
          background-color: #64727D;
          border-bottom: 3px solid #ffffff;
        }

        #cpu, #memory, #clock {
          padding: 0 10px;
          color: #ffffff;
        }

        #cpu {
          color: #33ccff;
        }

        #memory {
          color: #00ff99;
        }

        #clock {
          color: #ffffff;
          font-weight: bold;
        }
      '';
    };

    programs.emacs = {
      enable = true;
      package = pkgs.emacs-pgtk;
    };
  };

  system.stateVersion = "25.05";
}