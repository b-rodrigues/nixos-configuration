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
├── common.nix              # Shared config (hyprland, starship, fzf, packages)
├── apple-silicon/          # Mac-specific (Asahi firmware, notch waybar)
└── desktop/                # Desktop-specific (NVIDIA, 32-bit, libvirtd)
```

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
- **Solarized Dark** theme throughout (Starship, Ghostty, Qt/GTK)
- **fzf** keybindings: Ctrl+F (file path), Ctrl+G (cd), Ctrl+Y (copy), Ctrl+R (history)
- **rofi** scripts: Super+O (find files), Super+G (grep in files)
- Modern development tools: Emacs, Git, direnv, aider-chat

## New Machine Setup

When installing on new hardware:

1. Clone this repo
2. Copy the appropriate module folder (e.g., `modules/apple-silicon/`) or create a new one
3. **Update `system.stateVersion`** in the module's `default.nix` to match the NixOS version you're installing
4. Update `home.stateVersion` similarly
5. Generate and copy `hardware-configuration.nix`: `nixos-generate-config --show-hardware-config > modules/new-machine/hardware-configuration.nix`
6. Add the new host to `flake.nix`
7. Run `sudo nixos-rebuild switch --flake .#new-hostname`
