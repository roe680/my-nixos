{inputs,  nixpkgs, pkgs, ... }:
{
  # configuration.nix

  nix.settings = {
    substituters = ["https://nix-gaming.cachix.org"];
    trusted-public-keys = ["nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="];
  };

  programs = {
    gamescope = {
      enable = true;
      capSysNice = true;
    };
    steam.gamescopeSession.enable = true;
  };
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Remote Play用のポート開放
    dedicatedServer.openFirewall = true; # 専用サーバー用のポート開放
    localNetworkGameTransfers.openFirewall = true; # ローカルネットワーク転送用
    package = pkgs.steam.override {
      extraLibraries = pkgs :  [
        pkgs.libkrb5
        pkgs.keyutils
      ];
    }
    ;
  };
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    protonup-qt
    wine
    winetricks
    inputs.nix-gaming.packages.${pkgs.stdenv.hostPlatform.system}.wine-tkg
     # installs a package
  ];
}
