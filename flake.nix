{
  description = "NixOS configuration for Bruno - Desktop and Apple Silicon";

  inputs = {
    # Main NixOS release — the ambient pkgs set for both hosts (including
    # Brave, re-added upstream to release-26.05)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Bleeding edge: llama.cpp + fritchii (desktop), antigravity-cli, and
    # avd-fw / asahi-va-driver (macbook overlay bridge, used when the 26.05
    # input does not yet package them)
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # OpenCode v2 packaging (own branch of nixpkgs) — only opencode2 is taken
    nixpkgs-opencodev2.url = "github:b-rodrigues/nixpkgs/opencodev2";

    # Home Manager
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Apple Silicon support (kernel, firmware, etc.) - only used by macbook
    apple-silicon-support.url = "github:nix-community/nixos-apple-silicon/";
    apple-silicon-support.inputs.nixpkgs.follows = "nixpkgs";

    # Custom Iosevka font
    iosevka-custom.url = "github:b-rodrigues/iosevka_custom";
    iosevka-custom.inputs.nixpkgs.follows = "nixpkgs";

    # bootvine - live dependency tree of systemd jobs on the boot console
    # https://codeberg.org/wvhulle/bootvine
    bootvine = {
      url = "git+https://codeberg.org/wvhulle/bootvine";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      nixpkgs-unstable,
      nixpkgs-opencodev2,
      home-manager,
      apple-silicon-support,
      iosevka-custom,
      ...
    }:
    let
      # Single helper instead of one per source: import a nixpkgs tree with
      # unfree packages enabled and an optional cudaSupport knob (desktop
      # only). freebuff is vendored in modules/pkgs/freebuff and brave comes
      # from the ambient release-26.05 set, so no dedicated inputs for them.
      mkNixpkgs =
        src: system:
        { cudaSupport ? false }:
        import src {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = cudaSupport;
          };
        };
    in
    {
      # Desktop PC (x86_64)
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          pkgs-unstable = mkNixpkgs inputs.nixpkgs-unstable "x86_64-linux" { cudaSupport = true; };
          pkgs-opencodev2 = mkNixpkgs inputs.nixpkgs-opencodev2 "x86_64-linux" { };
        };
        modules = [
          ./modules/common.nix
          ./modules/desktop
          home-manager.nixosModules.default
          {
            fonts.packages = [ iosevka-custom.packages."x86_64-linux".default ];
          }
        ];
      };

      # MacBook (Apple Silicon / aarch64)
      nixosConfigurations.macbook = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = {
          inherit inputs;
          pkgs-unstable = mkNixpkgs inputs.nixpkgs-unstable "aarch64-linux" { };
          pkgs-opencodev2 = mkNixpkgs inputs.nixpkgs-opencodev2 "aarch64-linux" { };
        };
        modules = [
          # Apple Silicon support module
          apple-silicon-support.nixosModules.apple-silicon-support
          # Common and Mac-specific config
          ./modules/common.nix
          ./modules/apple-silicon
          # Home Manager
          home-manager.nixosModules.default
          # Custom Iosevka font
          {
            fonts.packages = [ iosevka-custom.packages."aarch64-linux".default ];
          }
        ];
      };
    };
}
