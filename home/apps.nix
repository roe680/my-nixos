{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  # home.nix
  imports = [
    inputs.zen-browser.homeModules.beta
    # or inputs.zen-browser.homeModules.twilight
    # or inputs.zen-browser.homeModules.twilight-official
  ];

  home.packages = with pkgs; [
    obsidian
    gnome-font-viewer
    aseprite
    cider
    blender
    zed-editor
    vlc
    discord
    libreoffice
    thunderbird
    prismlauncher
    warp-terminal
    vscode
  ];
  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;
  };

}
