{ pkgs ? import <nixpkgs> {}, username ? "roe", ... }:
let
  # arduino-language-server の stderr から非 UTF-8 バイトを除去するラッパー
  arduinoLspWrapped = pkgs.writeShellScriptBin "arduino-language-server-wrapped" ''
    #!${pkgs.bash}/bin/bash
    exec ${pkgs.arduino-language-server}/bin/arduino-language-server "$@" 2> >(${pkgs.glibc.bin}/bin/iconv -c -f UTF-8 -t UTF-8 >&2)
  '';

  # workspace/semanticTokens/refresh 等を clangd 側で横取りして
  # arduino-language-server に panic を起こさせないためのプロキシ。
  # ./clangd-refresh-guard.py を同じディレクトリに置いておくこと。
  clangdRefreshGuard = pkgs.writeShellScriptBin "clangd-refresh-guard" ''
    export CLANGD_REAL=${pkgs.llvmPackages_18.clang-tools}/bin/clangd
    exec ${pkgs.python3}/bin/python3 ${./clangd-refresh-guard.py} "$@"
  '';

  # Zed等、textDocument/didChangeをincremental(range付き)で送ってくる
  # クライアント向けに、差分を自前でフルテキストへ再構成してから
  # arduino-language-server-wrapped へ中継するプロキシ。
  # Arduino Language Server 0.7.7 はincremental差分の適用処理に
  # nil pointer panicするバグがあり、フルテキストしか送らない
  # Helixでは問題が起きないが、range付き差分を送るZedではpanicする。
  # ./als-full-sync-proxy.py を同じディレクトリに置いておくこと。
  arduinoLspFullSync = pkgs.writeShellScriptBin "arduino-language-server-fullsync" ''
    #!${pkgs.bash}/bin/bash
    exec ${pkgs.python3}/bin/python3 ${./als-full-sync-proxy.py} \
      ${arduinoLspWrapped}/bin/arduino-language-server-wrapped "$@"
  '';

  helixLanguagesToml = pkgs.writeText "arduino-languages.toml" ''
    [[language]]
    name = "ino"
    scope = "source.ino"
    file-types = ["ino", "h", "hpp", "cpp", "cc"]
    grammar = "cpp"
    language-servers = ["arduino-language-server"]
    comment-token = "//"
    roots = [".ino-root"]

    [language.indent]
    tab-width = 2
    unit = "  "

    [language-server.arduino-language-server]
    command = "${arduinoLspWrapped}/bin/arduino-language-server-wrapped"
    args = [
      "-cli", "${pkgs.arduino-cli}/bin/arduino-cli",
      "-clangd", "${clangdRefreshGuard}/bin/clangd-refresh-guard",
    ]
  '';
in
{
  environment.systemPackages = with pkgs; [
    bossa-arduino
    arduino-language-server
    arduino-cli
    arduino
    probe-rs-tools
    cargo-generate
    arduino-core
    rustup
    pkg-config
    libusb1
    pkgsCross.avr.buildPackages.gcc
    pkgsCross.avr.buildPackages.binutils
    pkgsCross.avr.buildPackages.avrdude
    dfu-util
    ravedude
    llvmPackages_18.clang-tools
    arduinoLspWrapped
    clangdRefreshGuard
    arduinoLspFullSync
    python3
  ];

  users.groups.plugdev = { };

  users.users.${username}.extraGroups = [
    "dialout"
    "plugdev"
  ];

  helix.languagesToml = helixLanguagesToml;

  # devShell から参照するため公開
  arduinoLspWrapped = arduinoLspWrapped;
  clangdRefreshGuard = clangdRefreshGuard;
  arduinoLspFullSync = arduinoLspFullSync;
}
