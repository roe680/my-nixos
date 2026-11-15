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
  xdg.mimeApps = {
  enable = true;

  defaultApplications = {
    "image/png" = "org.gnome.Loupe.desktop";
    "image/jpeg" = "org.gnome.Loupe.desktop";
    "image/webp" = "org.gnome.Loupe.desktop";
  };
};


  home.packages = with pkgs; [
    easyeffects
    rust-rover
    clion
    gimp
    music-discord-rpc
  	neovide
    ventoy-full-gtk
    loupe
    imv
    losslesscut
    google-chrome
    arduino-ide
    github-desktop
    github-copilot-cli
    obsidian
    freedoom
    gzdoom
    gnome-font-viewer
    aseprite
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
