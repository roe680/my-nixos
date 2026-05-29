{
  description = "Roe's Development Environments";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
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
        
        # 🦀 Rust単体環境
        rust = pkgs.mkShell {
          packages = (import ./home/rust.nix { inherit pkgs; }).home.packages or [];
          shellHook = ''echo "🦀 [to#rust] Rust環境をロードしました" '';
        };

        # 🎮 Bevyゲーム開発 ＆ Rust環境
        bevy = pkgs.mkShell {
          packages = 
            ((import ./home/rust.nix { inherit pkgs; }).home.packages or []) ++
            ((import ./home/bevy.nix { inherit pkgs; }).home.packages or []);
          shellHook = ''echo "🎮 [to#bevy] Bevyゲーム ＆ Rust環境をロードしました" '';
        };

        # 🔌 組み込みRust / ESP ＆ Arduino開発環境
        arduino-esp = pkgs.mkShell {
          packages = 
            ((import ./home/rust.nix { inherit pkgs; }).home.packages or []) ++
            ((import ./nixos/arduino.nix { inherit pkgs username; }).environment.systemPackages or []) ++
            ((import ./nixos/esp.nix { inherit pkgs lib username; }).environment.systemPackages or []);
          shellHook = ''echo "🔌 [to#arduino-esp] ESP/Arduino 組み込みRust環境をロードしました" '';
        };

        # ⚡ Zig環境
        zig = pkgs.mkShell {
          packages = (import ./home/zig.nix { inherit pkgs; }).home.packages or [];
          shellHook = ''echo "⚡ [to#zig] Zig環境をロードしました" '';
        };

        # 🛠️ C/C++環境
        clang-cpp = pkgs.mkShell {
          packages = 
            ((import ./home/clang.nix { inherit pkgs; }).home.packages or []) ++
            ((import ./home/cpp.nix { inherit pkgs; }).home.packages or []);
          shellHook = ''echo "🛠️ [to#clang-cpp] Clang & C++ 環境をロードしました" '';
        };

      };
    };
}
