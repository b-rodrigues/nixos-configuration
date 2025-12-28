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
