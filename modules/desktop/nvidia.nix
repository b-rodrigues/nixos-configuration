#===============================================================================
# NVIDIA GPU configuration for the desktop PC
#
# Tuned for a modern RTX 50-series card (for example, RTX 5060):
# - Uses the newest packaged NVIDIA driver available for this kernel.
# - Enables NVIDIA's open kernel module, which is the supported path for
#   recent NVIDIA GPUs.
# - Enables modesetting so Wayland/Hyprland and Plasma can use the card cleanly.
#===============================================================================

{ config, pkgs, ... }:

{
  # Use the NVIDIA driver for X11, XWayland, and Wayland compositors.
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Required for good Wayland support.
    modesetting.enable = true;

    # RTX 50-series GPUs are recent enough to use NVIDIA's open kernel module.
    open = true;

    # Keep the kernel module loaded to avoid first-launch latency for games and
    # GPU-accelerated applications.
    nvidiaPersistenced = true;

    # Useful GUI for checking driver/card state and changing NVIDIA settings.
    nvidiaSettings = true;

    # Use the freshest driver packaged for the configured kernel, which is what
    # new RTX generations generally need.
    package = config.boot.kernelPackages.nvidiaPackages.latest;

    # Enable suspend/resume handling. Fine-grained power management is mostly a
    # laptop concern, so leave it off for this desktop.
    powerManagement.enable = true;
    powerManagement.finegrained = false;
  };

  # Make common GPU diagnostics available on the desktop host.
  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia
  ];
}
