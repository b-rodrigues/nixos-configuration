# Binary cache configuration for Apple Silicon NixOS
{ pkgs, lib, ... }:

{
  nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
      # Apple Silicon binary cache (saves compiling the kernel)
      "https://nix-community.cachix.org"
      # R packages cache
      "https://rstats-on-nix.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "rstats-on-nix.cachix.org-1:vdiiVgocg6WeJrODIqdprZRUrhi1JzhBnXv7aWI6+F0="
    ];
  };
}
