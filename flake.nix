{
  description = "NixOS config for Bruno";

  inputs = {
    # Main NixOS release
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    # For Brave
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ nixpkgs, nixpkgs-unstable, home-manager, ... }:
  let
    system = "x86_64-linux";
  
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations.nixos =
      nixpkgs.lib.nixosSystem {
        inherit system;
  
        specialArgs = {
          inherit inputs pkgs-unstable;
        };
  
        modules = [
          ./configuration.nix
          home-manager.nixosModules.default
        ];
      };
  };

}
