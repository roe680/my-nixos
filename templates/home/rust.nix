{ pkgs, ... }:
{
  home.file.".cargo/config.toml".text = ''
    [target.x86_64-unknown-linux-gnu]
linker = "cc"
rustflags = ["-C", "link-arg=-fuse-ld=mold"]

[target.x86_64-pc-windows-gnu]
linker = "x86_64-w64-mingw32-gcc"
  '';

  home.packages = with pkgs; [
    rustup
    cargo-flamegraph
    cargo-binutils
    cargo-edit
    cargo-watch
    clang
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
