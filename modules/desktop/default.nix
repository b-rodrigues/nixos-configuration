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
  pkgs-unstable,
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
    ./network-watchdog.nix
    ./daily-reboot.nix
    ./tg-monitor.nix
  ]
  ++ (builtins.filter (f: builtins.pathExists f) [
    ./nvidia.nix # NVIDIA configuration (optional)
  ]);

  #=============================================================================
  # BOOT CONFIGURATION - Desktop specific
  #=============================================================================

  boot = {
    loader.efi.canTouchEfiVariables = true;
    kernelPackages = pkgs.linuxPackages_6_18;
  };

  # Enable CUDA globally for GPU-accelerated packages (llama-cpp, etc.)
  nixpkgs.config.cudaSupport = true;

  #=============================================================================
  # NETWORKING - Desktop specific
  #=============================================================================

  networking.hostName = "nixos";

  #=============================================================================
  # GRAPHICS - NVIDIA/Steam 32-bit support for x86_64
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

  # Incus - system container and VM manager (uses KVM)
  networking.nftables.enable = true;
  virtualisation.incus.enable = true;

  virtualisation.incus.preseed = {
    networks = [
      {
        name = "incusbr0";
        type = "bridge";
        config = {
          "ipv4.address" = "10.0.100.1/24";
          "ipv4.nat" = "true";
        };
      }
    ];
    storage_pools = [
      {
        name = "default";
        driver = "dir";
        config = {
          source = "/var/lib/incus/storage-pools/default";
        };
      }
    ];
    profiles = [
      {
        name = "default";
        devices = {
          root = {
            path = "/";
            pool = "default";
            type = "disk";
            size = "25GiB";
          };
        };
      }
    ];
  };

  # Allow DHCP and DNS on the Incus bridge
  networking.firewall.interfaces.incusbr0 = {
    allowedTCPPorts = [ 53 67 ];
    allowedUDPPorts = [ 53 67 ];
  };

  # Add desktop hardware/service groups to user
  users.users.brodrigues.extraGroups = lib.mkAfter [
    "libvirtd"
    "incus-admin"
    "uinput"
  ];

  #=============================================================================
  # PRINTING - Samsung driver (x86 only)
  #=============================================================================

  services.printing.drivers = [ pkgs.samsung-unified-linux-driver ];

  #=============================================================================
  # GAMING - Steam, SteamCMD, Sunshine, and helpers
  #=============================================================================

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;

    # Include a community Proton build so games that need newer compatibility
    # fixes have an out-of-the-box option in Steam's compatibility settings.
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  programs.gamemode.enable = true;

  # Sunshine exposes this desktop as a Moonlight-compatible game-streaming host.
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  # Let Sunshine create virtual input devices for Moonlight controllers, keyboard,
  # and mouse. Avahi user service publishing helps Moonlight discover the host on
  # the LAN instead of requiring manual IP entry.
  hardware.uinput.enable = true;
  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  #=============================================================================
  # Desktop-specific packages
  #=============================================================================

  environment.systemPackages = with pkgs; [
    air-formatter # Format R code (may not be available on aarch64)
    codex # OpenAI Codex
    gamescope # Nested Wayland compositor useful for troublesome games
    mangohud # In-game FPS/GPU overlay
    protonup-qt # GUI for managing additional Proton-GE versions
    steamcmd # Valve command-line tool for dedicated servers/tools

    # AI / Local LLM
    pkgs-unstable.llama-cpp # CUDA-enabled via nixpkgs.config.cudaSupport

    # Lichii (Frizti fork) Switch emulator; built from unstable (needs recent
    # cmake/SDL3/Qt6). Packaged in ./fritchii.
    (pkgs-unstable.callPackage ./fritchii { })
  ];

  #=============================================================================
  # AI - llama.cpp local model server (Qwen3.8-27B Uncensored IQ4_XS)
  # Inspired by Qwen3.8 16GB VRAM recipe (temperature 0.6, top-k 20, top-p 0.95,
  # flash-attn enabled, int4 KV cache, reasoning preservation).
  # With 13GB IQ4_XS weights on 16GB VRAM, context is tuned to 32k to prevent
  # spilling into system RAM. Lower quants (e.g. IQ3_M / EXL3 2.5bpw) allow 80k-176k+.
  #=============================================================================

  systemd.services.llama-server = {
    description = "llama.cpp OpenAI-compatible API server";
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = ''
        ${pkgs-unstable.llama-cpp}/bin/llama-server \
          -m /var/lib/llama-cpp/Qwen3.8-27B-Uncensored-IQ4_XS.gguf \
          --jinja \
          --host 127.0.0.1 \
          --port 8080 \
          -ngl 80 \
          --flash-attn on \
          --spec-type draft-mtp \
          --spec-draft-n-max 3 \
          -c 32768 \
          --parallel 1 \
          --cache-type-k q4_0 \
          --cache-type-v q4_0 \
          --temp 0.6 \
          --top-k 20 \
          --top-p 0.95 \
          --reasoning-preserve
      '';
      User = "brodrigues";
      Restart = "on-failure";
      RestartSec = "5";
      StateDirectory = "llama-cpp";
      StateDirectoryMode = "0755";
    };
  };

  #=============================================================================
  # AI - llama.cpp local model server #2 (Ternary-Bonsai-27B Q2_g64)
  # 27B-class ternary reasoning model (~7.2GB deployed). Q2_g64 is the pack
  # repacked for upstream llama.cpp (matches this repo's nixpkgs llama-cpp).
  # The full 262144-token architectural context only fits 16GB VRAM with the
  # 4-bit KV cache below (~12.8GB peak per the model card).
  # Model card sampling: temp 0.7, top-k 20, top-p 0.95 (thinking mode).
  # Cannot be VRAM-resident alongside the Qwen service; run one at a time.
  #=============================================================================

  systemd.services.llama-server-bonsai = {
    description = "llama.cpp OpenAI-compatible API server (Ternary-Bonsai-27B)";
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = ''
        ${pkgs-unstable.llama-cpp}/bin/llama-server \
          -m /var/lib/llama-cpp/Ternary-Bonsai-27B-Q2_g64.gguf \
          --alias ternary-bonsai-27B \
          --jinja \
          --host 127.0.0.1 \
          --port 8081 \
          -ngl 99 \
          --flash-attn on \
          -c 262144 \
          --parallel 1 \
          --cache-type-k q4_0 \
          --cache-type-v q4_0 \
          --temp 0.7 \
          --top-k 20 \
          --top-p 0.95 \
          --reasoning-preserve
      '';
      User = "brodrigues";
      Restart = "on-failure";
      RestartSec = "5";
      StateDirectory = "llama-cpp";
      StateDirectoryMode = "0755";
    };
  };

  #=============================================================================
  # WAYBAR - Standard single bar layout (no notch)
  #=============================================================================

  home-manager.users.brodrigues =
    { pkgs, ... }:
    let
      # Shared bar definition (modules/home/waybar-base.nix)
      waybarBase = pkgs.callPackage ../home/waybar-base.nix { };
    in
    {
      #---------------------------------------------------------------------------
      # LOCAL AI - llama.cpp server control + Incus VM helpers (desktop only)
      # The llama services live in this module; on other hosts these aliases
      # would reference services that do not exist.
      #---------------------------------------------------------------------------
      programs.bash = {
        shellAliases = {
          llamaup = "sudo systemctl start llama-server";
          llamadown = "sudo systemctl stop llama-server";
          llamastatus = "systemctl status llama-server";

          bonsaiup = "sudo systemctl start llama-server-bonsai";
          bonsaidown = "sudo systemctl stop llama-server-bonsai";
          bonsaistatus = "systemctl status llama-server-bonsai";

          # Incus VM management
          vm-start = "incus start test-vm";
          vm-stop = "incus stop test-vm";
          vm-status = "incus list test-vm";
          vm-shell = "incus exec test-vm -- bash";
          vm-kill = "incus delete --force test-vm";
        };

        profileExtra = ''
          # Incus Ubuntu VM helper - creates fresh VM with user 'incus'
          vm-setup() {
            local name="''${1:-test-vm}"

            # Clean up existing VM
            if incus info "$name" &>/dev/null; then
              echo "Removing existing VM '$name'..."
              incus delete --force "$name"
            fi

            # Launch fresh Ubuntu 24.04 VM
            echo "Creating Ubuntu 24.04 VM: $name ..."
            incus launch images:ubuntu/24.04 "$name" --vm \
              -c limits.cpu=4 \
              -c limits.memory=8GiB \
              -d root,size=20GiB

            # Wait for VM to be ready
            echo "Waiting for VM to boot..."
            for i in $(seq 1 30); do
              if incus exec "$name" -- true &>/dev/null; then
                break
              fi
              sleep 2
            done

            # Create user 'incus' with sudo
            echo "Creating user 'incus'..."
            incus exec "$name" -- useradd -m -s /bin/bash incus
            incus exec "$name" -- bash -c 'echo "incus:incus" | chpasswd'
            incus exec "$name" -- usermod -aG sudo incus

            # Show result
            local ip=$(incus list "$name" -c ipv4 --format csv | tr -d '\n')
            echo ""
            echo "VM ready!"
            echo "  Login:   incus exec $name -- su - incus"
            echo "  IP:      $ip"
            echo "  User:    incus / incus"
          }
        '';
      };

      programs.waybar = {
        enable = true;

        # Shared bar definition (modules/home/waybar-base.nix) - this
        # host uses the defaults. `style` below is its own CSS.
        settings.mainBar = waybarBase.mkMainBar { };

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

      #---------------------------------------------------------------------------
      # OpenCode - local llama.cpp models (Qwen3.8-27B, Ternary-Bonsai-27B)
      #---------------------------------------------------------------------------
      home.file.".config/opencode/opencode.jsonc" = {
        force = true;
        text = ''
        {
          "$schema": "https://opencode.ai/config.json",
          "provider": {
            "llama.cpp": {
              "npm": "@ai-sdk/openai-compatible",
              "name": "llama.cpp (local Qwen3.8-27B Uncensored)",
              "options": {
                "baseURL": "http://127.0.0.1:8080/v1"
              },
              "models": {
                "Qwen3.8-27B-Uncensored-IQ4_XS.gguf": {
                  "name": "Qwen3.8-27B Uncensored (IQ4_XS)",
                  "reasoning": true,
                  "limit": {
                    "context": 32768,
                    "output": 8192
                  }
                }
              }
            },
            "llama-bonsai": {
              "npm": "@ai-sdk/openai-compatible",
              "name": "llama.cpp (local Ternary-Bonsai-27B)",
              "options": {
                "baseURL": "http://127.0.0.1:8081/v1"
              },
              "models": {
                "ternary-bonsai-27B": {
                  "name": "Ternary-Bonsai-27B (Q2_g64)",
                  "reasoning": true,
                  "limit": {
                    "context": 262144,
                    "output": 32768
                  }
                }
              }
            },
            "opencode": {}
          }
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
