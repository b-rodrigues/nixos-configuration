# NixOS Configuration

Unified NixOS configuration for Bruno's machines with Hyprland desktop environment.

## Machines

| Host | Architecture | Description |
|------|--------------|-------------|
| `macbook` | aarch64 | MacBook M2 Air with Asahi Linux |
| `nixos` | x86_64 | Desktop PC with NVIDIA GPU |

## Structure

```
modules/
├── common.nix              # Shared NixOS-level config (boot, locale, packages lists)
├── scripts/*.sh            # Shared shell scripts, installed as PATH commands
├── scripts.nix             # writeShellScriptBin wrappers (PATH preludes)
├── pkgs/freebuff/          # Vendored freebuff package (was a dedicated nixpkgs fork input)
├── home/
│   ├── base.nix            # Shared home-manager config (shell, Hyprland, theme wiring, tools)
│   ├── theme.nix           # Solarized Dark palette - single source for all colors
│   └── waybar-base.nix     # Shared waybar top bar; hosts pass overrides
├── apple-silicon/          # Mac-specific: Asahi firmware, notch waybar, avd-fw bridge
└── desktop/                # Desktop-specific: NVIDIA/32-bit, libvirtd, llama servers, waybar
```

## Flake inputs

Only three nixpkgs trees are evaluated per rebuild:

- `nixpkgs` (`nixos-26.05`) — ambient set for both hosts
- `nixpkgs-unstable` — llama.cpp/fritchii (desktop), antigravity-cli, avd-fw + asahi-va-driver bridge (macbook)
- `nixpkgs-opencodev2` — `opencode2` only

Dedicated `nixpkgs-brave` (Brave — now in the ambient pin) and `nixpkgs-freebuff`
(now vendored in `modules/pkgs/freebuff`) inputs were dropped; `nixpkgs-master`
was folded into unstable.

## Usage

```bash
# Rebuild current machine (auto-detects hostname)
rebuild

# Update flake and rebuild
upgrade

# Test without activating
rebuild-test

# Rollback to previous generation
rollback

# Garbage collect
gc
```

## Features

- **Hyprland** window manager with BÉPO keyboard layout
- **Solarized Dark** theme throughout — single-sourced in
  [`modules/home/theme.nix`](modules/home/theme.nix) and interpolated into kdeglobals, dunst,
  fzf, starship, hyprland, ghostty and the waybar CSS
- **fzf** keybindings: Ctrl+F (file path), Ctrl+G (cd), Ctrl+Y (copy), Ctrl+R (history)
- **rofi** scripts: Super+O (find files), Super+G (grep in files)
- **Desktop only:** llama.cpp model servers (`llamaup`/`down`/`status`, bonsai variants),
  Incus VM helpers (`vm-setup`, `vm-start`, ...) defined next to the services they drive
- **Desktop only:** Telegram inbox monitor (`modules/desktop/tg-monitor.nix`) — a user
  service consuming `tg read -f -r -q --catch-up` as raw getUpdates JSON, queueing bare
  message text to `~/.local/share/tg-monitor/inbox.log` with per-message acks. Same chat
  filter as the `tg` helper; dedupe keys on (chat, message, text)
- Modern development tools: Emacs, Git, direnv, aider-chat
- **Shared shell scripts** as real files under `modules/scripts/` (tg, llm, rofi-files,
  rofi-grep, clipboard menus, nixpr-review, ...) instead of inline Nix strings

## New Machine Setup

When installing on new hardware:

1. Clone this repo
2. Copy the appropriate module folder (e.g., `modules/apple-silicon/`) or create a new one
3. **Update `system.stateVersion`** in the module's `default.nix` to match the NixOS version you're installing
4. Update `home.stateVersion` similarly
5. Generate and copy `hardware-configuration.nix`: `nixos-generate-config --show-hardware-config > modules/new-machine/hardware-configuration.nix`
6. Add the new host to `flake.nix`
7. Run `sudo nixos-rebuild switch --flake .#new-hostname`
