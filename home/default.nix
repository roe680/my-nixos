{ inputs, username, ... }:

{
  imports = [
    ./kicad.nix
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
    desktopEntries.dmmgameplayer-uri = {
      name = "DMMGamePlayer URI Handler";
      exec = "/home/roe/.local/bin/dmmgameplayer-uri %u";
      type = "Application";
      terminal = false;
      noDisplay = true;
      mimeType = [
        "x-scheme-handler/dmmgameplayer"
      ];
    };

    mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/dmmgameplayer" = "dmmgameplayer-uri.desktop";
      };
    };
    enable = true;
    userDirs = {
      enable = true;
      setSessionVariables = true;
    };
  };

  programs.home-manager.enable = true;
}
