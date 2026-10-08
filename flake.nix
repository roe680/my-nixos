{
  description = "NixOS + Home Manager configuration";
  inputs = {

    nix-gaming.url = "github:fufexan/nix-gaming";
    niri.url = "github:sodiboo/niri-flake";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-hazkey = {
      url = "github:aster-void/nix-hazkey";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    xdg-portal-termfilepickers = {
      url = "github:Guekka/xdg-desktop-portal-termfilepickers"; # ← ここを修正
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    quickshell = {
      url = "github:outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    elephant.url = "github:abenz1267/elephant";
    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
    };
    zjstatus = {
      url = "github:dj95/zjstatus";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      agenix,
      walker,
      noctalia,
      zjstatus,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      hostname = "nixos";
      username = "roe";
      inherit (inputs.nixpkgs.lib) attrValues;
      overlays = with inputs; [
        (final: prev: {
          stdenv = prev.stdenvAdapters.useMoldLinker prev.stdenv;
        })
        (final: prev: {
          zjstatus = zjstatus.packages.${prev.stdenv.hostPlatform.system}.default;
        })
      ];
      pkgs-stable = import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };
    in
    {

      nixosConfigurations.${hostname} = nixpkgs-unstable.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit
            inputs
            pkgs-stable
            username
            hostname
            ;
        };
        modules = [
          ./configuration.nix
          { nixpkgs.overlays = overlays; }
          home-manager.nixosModules.home-manager
          {
            home-manager.backupFileExtension = "backup";
            home-manager.useGlobalPkgs = true;
            home-manager.sharedModules = [
              inputs.niri.homeModules.niri # ← ここ
              inputs.walker.homeManagerModules.default
              inputs.noctalia.homeModules.default
            ];
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs username; };
            home-manager.users.${username} = import ./home;
          }
          agenix.nixosModules.default
          inputs.nix-hazkey.nixosModules.hazkey
        ];
      };
    };
}
