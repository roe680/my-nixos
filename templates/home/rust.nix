{ pkgs, ... }:
{
  home.file.".cargo/config.toml".text = ''
    [target.'cfg(target_os = "linux")']
    linker = "${pkgs.clang}/bin/clang"
    rustflags = ["-C", "link-arg=-fuse-ld=${pkgs.mold}/bin/mold"]

    # Windows向けクロスコンパイル
    [target.x86_64-pc-windows-gnu]
    linker = "${pkgs.llvmPackages.lld}/bin/lld"
  '';

  home.packages = with pkgs; [
    rustup
    rustfmt
    cargo-flamegraph
    cargo-binutils
    cargo-edit
    cargo-watch
  ];

  programs.helix.languages = {
    language = [
      {
        name = "rust";
        auto-format = true;
        language-servers = [ "rust-analyzer" ];
      }
    ];

    language-server.rust-analyzer = {
      command = "${pkgs.util-linux}/bin/taskset";
      args = [
        "-c"
        "0-15"
        "rust-analyzer"
      ];
      config = {
        lru = {
          capacity = 2048;
        };
      };
    };
  };
}
