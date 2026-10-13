{ inputs, username, ... }:

{
  imports = [
    ./neovim.nix
    ./zellij.nix
    ./walker.nix
    ./terminal.nix
    ./niri.nix
    ./editors.nix
    ./cli-tools.nix
    ./development.nix
    ./apps.nix
    ./noctalia.nix
    ../templates/home/rust.nix
  ];

  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = "24.11";
  };

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      setSessionVariables = true;
    };
    mimeApps.enable = true;
  };

  programs.home-manager.enable = true;
}
