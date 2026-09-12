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

      username = "roe";

      arduino = import ./nixos/arduino.nix {
        inherit pkgs username;
      };

      esp = import ./nixos/esp.nix {
        inherit pkgs lib username;
      };

    in
    {
      devShells.${system} = {

        # 🦀 Rust
        rust = pkgs.mkShell {
          packages =
            (import ./home/rust.nix {
              inherit pkgs;
            }).home.packages or [ ];

          shellHook = ''
            echo "🦀 [to#rust] Rust環境をロードしました"
          '';
        };

        # 🎮 Bevy
        bevy = pkgs.mkShell {
          packages =
            ((import ./home/rust.nix {
              inherit pkgs;
            }).home.packages or [ ]
            )
            ++ ((import ./home/bevy.nix {
              inherit pkgs;
            }).home.packages or [ ]
            );

          shellHook = ''
            echo "🎮 [to#bevy] Bevyゲーム ＆ Rust環境をロードしました"
          '';
        };

        # 🔌 Arduino / ESP
        arduino-esp = pkgs.mkShell {

          packages =
            ((import ./home/rust.nix {
              inherit pkgs;
            }).home.packages or [ ]
            )
            ++ arduino.environment.systemPackages
            ++ esp.environment.systemPackages;

          shellHook = ''
                        echo "🔌 [to#arduino-esp] ESP/Arduino 組み込みRust環境をロードしました"

                        HELIX_TOML="${arduino.helix.languagesToml}"

                        # ------------------------------------------------------------
                        # Arduino プロジェクト判定
                        # ------------------------------------------------------------

                        if ls *.ino >/dev/null 2>&1; then

                          echo "  → Arduinoプロジェクトを検出しました"


                          # ----------------------------------------------------------
                          # Helix
                          # ----------------------------------------------------------

                          mkdir -p .helix

                          if [ ! -e .helix/languages.toml ]; then
                            cp "$HELIX_TOML" .helix/languages.toml
                            chmod +w .helix/languages.toml

                            echo "  → .helix/languages.toml を生成しました"
                          fi


                          # ----------------------------------------------------------
                          # Arduino Language Server の root
                          # ----------------------------------------------------------

                          if [ ! -e .ino-root ]; then
                            touch .ino-root

                            echo "  → .ino-root を生成しました"
                          fi


                          # ----------------------------------------------------------
                          # sketch.yaml
                          # ----------------------------------------------------------

                          if [ ! -e sketch.yaml ]; then

                            printf '%s\n' \
                              'default_fqbn: arduino:avr:mega' \
                              > sketch.yaml

                            echo "  → sketch.yaml を生成しました"
                          fi


                          # ----------------------------------------------------------
                          # .clangd
                          # ----------------------------------------------------------

                          if [ ! -e .clangd ]; then

                            cat > .clangd <<'EOF'
            CompileFlags:
              Add:
                - "-nostdinc"
                - "-U__i386__"
                - "-U__x86_64__"
                - "-D__AVR__"
            EOF

                            echo "  → .clangd を生成しました"
                          fi


                          # ----------------------------------------------------------
                          # Zed
                          # ----------------------------------------------------------

                          mkdir -p .zed

                          if [ ! -e .zed/settings.json ]; then

                            cat > .zed/settings.json <<EOF
            {
              ...
              "lsp": {
                "arduino-language-server": {
                  "binary": {
                    "path": "${arduino.arduinoLspFullSync}/bin/arduino-language-server-fullsync",
                    "arguments": [
                      "-cli",
                      "${pkgs.arduino-cli}/bin/arduino-cli",
                      "-clangd",
                      "${arduino.clangdRefreshGuard}/bin/clangd-refresh-guard"
                    ]
                  }
                }
              }
            }
            EOF
                            echo "  → .zed/settings.json を生成しました"
                          fi

                        else

                          echo "  ⚠  .inoファイルが見つからないため、Arduinoプロジェクト設定を生成しませんでした"

                        fi
          '';
        };

        # ⚡ Zig
        zig = pkgs.mkShell {
          packages =
            (import ./home/zig.nix {
              inherit pkgs;
            }).home.packages or [ ];

          shellHook = ''
            echo "⚡ [to#zig] Zig環境をロードしました"
          '';
        };

        # 🛠 C/C++
        clang-cpp = pkgs.mkShell {
          packages =
            ((import ./home/clang.nix {
              inherit pkgs;
            }).home.packages or [ ]
            )
            ++ ((import ./home/cpp.nix {
              inherit pkgs;
            }).home.packages or [ ]
            );

          shellHook = ''
            echo "🛠 [to#clang-cpp] Clang & C++ 環境をロードしました"
          '';
        };

      };
    };
}
