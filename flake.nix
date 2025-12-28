{
  description = "NixOS configuration for Bruno - Desktop and Apple Silicon";

  inputs = {
    # Main NixOS release
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    # For packages from unstable (like Brave)
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Apple Silicon support (kernel, firmware, etc.) - only used by macbook
    apple-silicon-support.url = "github:nix-community/nixos-apple-silicon";
    apple-silicon-support.inputs.nixpkgs.follows = "nixpkgs";

    # Custom Iosevka font
    iosevka-custom.url = "github:b-rodrigues/iosevka_custom";
    iosevka-custom.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ nixpkgs, nixpkgs-unstable, home-manager, apple-silicon-support, iosevka-custom, ... }:
  let
    # Desktop (x86_64)
    mkDesktopPkgs = system: import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };

    # Apple Silicon (aarch64)
    mkMacPkgs = system: import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    # Desktop PC (x86_64)
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
        pkgs-unstable = mkDesktopPkgs "x86_64-linux";
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
        pkgs-unstable = mkMacPkgs "aarch64-linux";
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
