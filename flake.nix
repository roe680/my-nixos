{
  description = "NixOS + Home Manager configuration";
  inputs = {

    nix-gaming.url = "github:fufexan/nix-gaming";
    niri.url = "github:sodiboo/niri-flake";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    microchip = {
      url = "github:cormacc/nix-microchip";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
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
        microchip.overlays.default
        (final: prev: {
          zjstatus = zjstatus.packages.${prev.stdenv.hostPlatform.system}.default;
        })
      ];
      pkgs-stable = import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };
      pkgs = import nixpkgs-unstable {
        inherit system overlays;
        config.allowUnfree = true;
      };
      espTools = [
        "espflash"
        "esp-generate"
        "espup"
      ];
    in
    {
      devShells.${system} = {
        esp = pkgs.mkShell {
          packages = with pkgs; [
            rustup
            cargo
            rustc
            cargo-binstall
            pkg-config
            openssl
            systemd
          ];

          shellHook = ''
            export PATH="$HOME/.cargo/bin:$PATH"
            cargo binstall --no-confirm --locked ${
              pkgs.lib.concatStringsSep " " espTools
            } || true

            if command -v espup >/dev/null 2>&1; then
              if [ ! -f "$HOME/export-esp.sh" ]; then
                espup install
              fi

              if [ -f "$HOME/export-esp.sh" ]; then
                source "$HOME/export-esp.sh"
              fi
            fi
          '';
        };

        pic = pkgs.mkShell {
          packages = [
            pkgs.mplab-x
            (pkgs.writeShellScriptBin "pic-write" ''
              set -eu

              if [ "$#" -ne 1 ]; then
                echo "usage: pic-write firmware.hex" >&2
                exit 2
              fi

              firmware=$1
              if [ ! -f "$firmware" ]; then
                echo "pic-write: HEX file not found: $firmware" >&2
                exit 1
              fi

              exec ipecmd -TPSNAP -P18F47Q43 -F"$firmware" -E -M -OL
            '')
          ];
          shellHook = ''
            echo "PIC18F47Q43 / MPLAB SNAP environment"
            echo "Write a HEX file with: pic-write firmware.hex"
          '';
        };
      };

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
          {
            nixpkgs.overlays = overlays ++ [
              (final: prev: {
                linuxPackages_zen = prev.linuxPackages_zen.extend (
                  kernelFinal: kernelPrev: {
                    v4l2loopback = kernelPrev.v4l2loopback.overrideAttrs (old: {
                      postInstall = (old.postInstall or "") + ''
                        rm -f "$out/lib/modules/${kernelFinal.kernel.modDirVersion}"/modules.*
                      '';
                    });
                  }
                );
              })
            ];
          }
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
