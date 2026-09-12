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

  # ------------------------------------------------------------------
  # Zed向け: didChangeの取りこぼし/競合対策プロキシ
  #
  # 検証の結果、Arduino Language Server 0.7.7は
  #   - initialize応答でtextDocumentSync=Incrementalを宣言しており、
  #     range付き差分しか想定していない
  #   - range無しのフルテキスト置き換えを送ると
  #     panic("full-text change not implemented") で明示的に落ちる
  #     (以前試した「フルテキストへ変換するプロキシ」はこれを踏み抜いていた)
  #   - 一方、素のincremental差分そのものでも、短時間に連続した
  #     didChange(例: Zedのオートインデントによる2連続変更が
  #     数十マイクロ秒間隔で送られてくるケース)で、内部状態の
  #     構築が終わる前に次のdidChangeを受理してしまい、
  #     nilデリファレンスでpanicする(ls.go:1130)ことを確認済み。
  #
  # このプロキシは中身を一切変換せず、短時間(既定30ms)以内に
  # 連続して届いたdidChangeは最新の1件だけを採用してまとめて
  # 送ることで、この競合状態を外側から緩和する。
  # ./als-serialize-proxy.py を同じディレクトリに置いておくこと。
  arduinoLspSerialize = pkgs.writeShellScriptBin "arduino-language-server-serialize" ''
    #!${pkgs.bash}/bin/bash
    exec ${pkgs.python3}/bin/python3 ${./als-serialize-proxy.py} \
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
    arduinoLspSerialize
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
  arduinoLspSerialize = arduinoLspSerialize;
}
