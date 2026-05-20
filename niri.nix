{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [ ./wayland-core.nix
     ];
  

  environment.systemPackages = with pkgs; [
    xwayland-satellite
    grim
    slurp
    wl-clipboard
    cliphist
    hyprpicker
    brightnessctl
    playerctl
    upower
    stress-ng

    lm_sensors
    kdePackages.polkit-kde-agent-1
    xdg-desktop-portal-gtk
xdg-desktop-portal-gnome
    nautilus
    # noctalia は home/noctalia.nix で管理
  ];
}
