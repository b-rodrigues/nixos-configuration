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

    # Nixpkgs Master (for cutting edge packages like antigravity)
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";

    # Apple Silicon support (kernel, firmware, etc.) - only used by macbook
    # Pinned to kernel 6.17.12 due to notch regression in 6.18.x
    # See: https://github.com/nix-community/nixos-apple-silicon/commit/aa6cb2eec178e43cefa244f18647be60d3d49378
    apple-silicon-support.url = "github:nix-community/nixos-apple-silicon/aa6cb2eec178e43cefa244f18647be60d3d49378";
    apple-silicon-support.inputs.nixpkgs.follows = "nixpkgs";

    # Custom Iosevka font
    iosevka-custom.url = "github:b-rodrigues/iosevka_custom";
    iosevka-custom.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      nixpkgs,
      nixpkgs-unstable,
      nixpkgs-master,
      home-manager,
      apple-silicon-support,
      iosevka-custom,
      ...
    }:
    let
      # Desktop (x86_64)
      mkDesktopPkgs =
        system:
        import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };

      # Apple Silicon (aarch64)
      mkMacPkgs =
        system:
        import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };

      mkMasterPkgs =
        system:
        import nixpkgs-master {
          inherit system;
          config.allowUnfree = true;
        };
    in
    {
      # Desktop PC (x86_64)
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          pkgs-unstable = mkDesktopPkgs "x86_64-linux";
          pkgs-master = mkMasterPkgs "x86_64-linux";
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
          pkgs-master = mkMasterPkgs "aarch64-linux";
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
