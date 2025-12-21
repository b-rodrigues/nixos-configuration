{
  description = "NixOS config for Bruno - Apple Silicon";
  inputs = {
    # Main NixOS release
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    # For packages from unstable (like Brave)
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Home Manager
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # Apple Silicon support (kernel, firmware, etc.)
    apple-silicon-support.url = "github:nix-community/nixos-apple-silicon";
    apple-silicon-support.inputs.nixpkgs.follows = "nixpkgs";
    # Custom Iosevka font
    iosevka-custom.url = "github:b-rodrigues/iosevka_custom";
    iosevka-custom.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs@{ nixpkgs, nixpkgs-unstable, home-manager, apple-silicon-support, iosevka-custom, ... }:
  let
    system = "aarch64-linux";
  
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations.macbook = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs pkgs-unstable;
      };
      modules = [
        # Apple Silicon support module
        apple-silicon-support.nixosModules.apple-silicon-support
        # Your configuration
        ./configuration.nix
        # Home Manager
        home-manager.nixosModules.default
        # Custom Iosevka font
        {
          fonts.packages = [ iosevka-custom.packages.${system}.default ];
        }
      ];
    };
  };
}
