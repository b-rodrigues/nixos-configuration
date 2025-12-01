#===============================================================================
# NVIDIA Hardware Configuration Module
# Author: Bruno Rodrigues and Claude
#
# This file is automatically included if it exists.
# Delete or rename this file on non-NVIDIA machines.
#===============================================================================

{ config, pkgs, ... }:

{
  #=============================================================================
  # NVIDIA-SPECIFIC GRAPHICS CONFIGURATION
  # Optimized for Wayland + NVIDIA with proper power management
  #=============================================================================

  # Configure NVIDIA driver for both X11 and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Essential for Wayland compositors
    modesetting.enable = true;

    # Power Management Settings
    # Note: Basic power management is disabled as it can cause sleep issues
    # Enable only if experiencing corruption after wake from sleep
    powerManagement = {
      enable = false;      # Basic power management
      finegrained = false; # Fine-grained power management (Turing+ only)
    };

    # Driver Selection
    # Use proprietary driver for maximum compatibility and performance
    # Open-source driver is still experimental (alpha quality)
    open = false;

    # Enable NVIDIA control panel access
    nvidiaSettings = true;

    # Use stable driver for GTX 1080 (Pascal architecture)
    # Alternative: config.boot.kernelPackages.nvidiaPackages.legacy_470
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  #=============================================================================
  # NVIDIA-SPECIFIC PACKAGES
  #=============================================================================
  
  environment.systemPackages = with pkgs; [
    nvidia-vaapi-driver         # Hardware video acceleration
    libva-vdpau-driver
    libvdpau-va-gl
  ];
  
  #=============================================================================
  # NVIDIA-SPECIFIC ENVIRONMENT VARIABLES
  #=============================================================================
  
  environment.sessionVariables = {
    # NVIDIA Wayland optimization
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    
    # Fix cursor rendering issues with NVIDIA
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  #=============================================================================
  # NVIDIA-SPECIFIC HYPRLAND CONFIGURATION
  #=============================================================================
  
  # Add NVIDIA-specific environment variables to Hyprland
  home-manager.users.brodrigues.wayland.windowManager.hyprland.settings.env = [
    "LIBVA_DRIVER_NAME,nvidia"
    "XDG_SESSION_TYPE,wayland"
    "GBM_BACKEND,nvidia-drm"
    "__GLX_VENDOR_LIBRARY_NAME,nvidia"
    "WLR_NO_HARDWARE_CURSORS,1"
  ];

  # NVIDIA-specific rendering optimizations for Hyprland
  home-manager.users.brodrigues.wayland.windowManager.hyprland.settings.render = {
    explicit_sync = 2;
    explicit_sync_kms = 2;
  };

  # NVIDIA-specific misc settings for Hyprland
  home-manager.users.brodrigues.wayland.windowManager.hyprland.settings.misc.vrr = 0;  # Variable refresh rate off (can cause issues)
}