{
  description = "Roe's Development Environments";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = nixpkgs.lib;

      # モジュール群に渡すためのダミー・最小限の引数を定義
      # (mkShell側ではシステムの設定値は反映されないため、評価を通すための値です)
      username = "roe";
    in
    {
      devShells.${system} = {
        rust = pkgs.mkShell {
  packages = (import ./home/rust.nix { inherit pkgs; }).home.packages or [ ];

  nativeBuildInputs = with pkgs; [
    pkg-config
  ];

  buildInputs = with pkgs; [
    fontconfig
    systemd
  ];

  shellHook = ''
    echo "🦀 [to#rust] Rust環境をロードしました"
  '';
};
        
        # 🎮 Bevyゲーム開発 ＆ Rust環境
        bevy = pkgs.mkShell {
          packages =
            ((import ./home/rust.nix { inherit pkgs; }).home.packages or [ ])
            ++ ((import ./home/bevy.nix { inherit pkgs; }).home.packages or [ ]);
          shellHook = ''echo "🎮 [to#bevy] Bevyゲーム ＆ Rust環境をロードしました" '';
        };
        arduino-esp = pkgs.mkShell {
          packages =
            ((import ./home/rust.nix { inherit pkgs; }).home.packages or [ ])
            ++ ((import ./nixos/arduino.nix { inherit pkgs username; }).environment.systemPackages or [ ])
            ++ ((import ./nixos/esp.nix { inherit pkgs lib username; }).environment.systemPackages or [ ]);
          shellHook = ''
                        echo "🔌 [to#arduino-esp] ESP/Arduino 組み込みRust環境をロードしました"
                        

                        HELIX_TOML="${
                          (import ./nixos/arduino.nix { inherit pkgs username; }).helix.languagesToml
                        }"

                        if ls *.ino >/dev/null 2>&1; then
                          mkdir -p .helix
                          if [ ! -e .helix/languages.toml ]; then
                            cp "$HELIX_TOML" .helix/languages.toml
                            chmod +w .helix/languages.toml
                            echo "  → .helix/languages.toml を生成しました"
                          fi
                          if [ ! -e .ino-root ]; then
                            touch .ino-root
                            echo "  → .ino-root を生成しました"
                          fi

                          # clangd 向けにホストヘッダー遮断設定を自動生成
                          if [ ! -e .clangd ]; then
                            cat << 'EOF' > .clangd
            CompileFlags:
              Add:
                - "-nostdinc"
                - "-U__i386__"
                - "-U__x86_64__"
                - "-D__AVR__"
            EOF
                            echo "  → .clangd を生成しました"
                          fi
                        else
                          echo "  ⚠️  .inoファイルが見つからないため、環境設定ファイルは生成しませんでした"
                        fi
          '';
        };
        # ⚡ Zig環境
        zig = pkgs.mkShell {
          packages = (import ./home/zig.nix { inherit pkgs; }).home.packages or [ ];
          shellHook = ''echo "⚡ [to#zig] Zig環境をロードしました" '';
        };

        # 🛠️ C/C++環境
        clang-cpp = pkgs.mkShell {
          packages =
            ((import ./home/clang.nix { inherit pkgs; }).home.packages or [ ])
            ++ ((import ./home/cpp.nix { inherit pkgs; }).home.packages or [ ]);
          shellHook = ''echo "🛠️ [to#clang-cpp] Clang & C++ 環境をロードしました" '';
        };

      };
    };
}
