{
  description = "Roe's Development Environments";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "copilot-language-server"
          ];
      };
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
        # ...(以下は変更なし)
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
              "file_types": {
                "Arduino": [
                  "ino",
                  "cpp",
                  "cc",
                  "h",
                  "hpp"
                ]
              },

              "languages": {
                "Arduino": {
                  "language_servers": [
                    "arduino-language-server"
                  ]
                }
              },

              "lsp": {
                "arduino-language-server": {
                  "binary": {
                    "path": "${arduino.arduinoLspWrapped}/bin/arduino-language-server-wrapped",
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

        # 🦀 ESP-RS
        esp-rs = pkgs.mkShell {
          packages =
            ((import ./home/rust.nix {
              inherit pkgs;
            }).home.packages or [ ]
            )
            ++ esp.environment.systemPackages
            ++ (with pkgs; [
              probe-rs-tools
              pkg-config
              libusb1
              dfu-util
              minicom
              picocom
            ]);

          LIBCLANG_PATH = "/home/${username}/.rustup/toolchains/esp/xtensa-esp32-elf-clang/esp-20.1.1_20250829/esp-clang/lib";

          shellHook = ''
            export PATH="/home/${username}/.rustup/toolchains/esp/xtensa-esp-elf/esp-15.2.0_20250920/xtensa-esp-elf/bin:$PATH"

            echo "🦀 [to#esp-rs] ESP-RS 環境をロードしました"
          '';
        };

          services.udev.packages = [ pkgs.platformio-core.udev ];
        # 🔌 PlatformIO
        
        platformio = pkgs.mkShell {
          
          packages =
            ((import ./home/cpp.nix {
              inherit pkgs;
            }).home.packages or [ ]
            )
            ++ (with pkgs; [
              platformio-core
              platformio
              python3
              avrdude
              ccache
              dfu-util
              minicom
              picocom
            ]);
shellHook = ''
  echo "🔌 [to#platformio] PlatformIO 環境をロードしました"

  if [ -d "$HOME/.platformio/packages" ]; then
    find "$HOME/.platformio/packages" \
      -type f -perm /111 \
      -exec sed -i \
        '1s|^#!/bin/bash|#!${pkgs.bash}/bin/bash|' {} +
  fi

  echo "🔌 [to#platformio] PlatformIO 環境をロードしました"
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

        # 🐦 Swift
        swift = pkgs.mkShell {
          packages =
            (import ./home/swift.nix {
              inherit pkgs;
            }).home.packages or [ ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
            pkgs.ncurses
            pkgs.libedit
            pkgs.swift
            pkgs.swift-corelibs-libdispatch
            pkgs.glibc
          ];

          shellHook = ''
            echo "🐦 [to#swift] Swift環境をロードしました"
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
