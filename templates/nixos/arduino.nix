{ pkgs ? import <nixpkgs> {}, username ? "roe", ... }:
let
  arduino-language-server-rc = pkgs.stdenv.mkDerivation {
    pname = "arduino-language-server";
    version = "0.8.0-rc.1";

    src = pkgs.fetchurl {
      url = "https://github.com/arduino/arduino-language-server/releases/download/0.8.0-rc.1/arduino-language-server_0.8.0-rc.1_Linux_64bit.tar.gz";
      hash = "sha256-b4AnvfxC/Uj8gKJ0zaLMUgJSfe6Iwxt3UHiO9d6G3bs="; # ← 実際のSRI hash
    };

    sourceRoot = ".";

    installPhase = ''
      install -Dm755 arduino-language-server_linux_amd64/arduino-language-server \
        $out/bin/arduino-language-server
    '';
  };

  # nixpkgs に入っている copilot-language-server をそのまま利用
  copilotLsp = pkgs.copilot-language-server;

  # arduino-language-server の stderr から非 UTF-8 バイトを除去するラッパー
  arduinoLspWrapped = pkgs.writeShellScriptBin "arduino-language-server-wrapped" ''
    #!${pkgs.bash}/bin/bash
    exec ${arduino-language-server-rc}/bin/arduino-language-server "$@" 2> >(${pkgs.glibc.bin}/bin/iconv -c -f UTF-8 -t UTF-8 >&2)
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

    # --- GitHub Copilot LSP ---
    [language-server.copilot]
    command = "${copilotLsp}/bin/copilot-language-server"
    args = ["--stdio"]

    [language-server.copilot.config]
    editor.name = "helix"
    editor.version = "24.0"
    editorPlugin.name = "helix-copilot"
    editorPlugin.version = "0.1.0"

    # --- 既定の language-servers を維持しつつ copilot を追加 ---
    [[language]]
    name = "zig"
    language-servers = ["zls", "copilot"]

    [[language]]
    name = "c"
    language-servers = ["clangd", "copilot"]

    [[language]]
    name = "cpp"
    language-servers = ["clangd", "copilot"]

    [[language]]
    name = "rust"
    language-servers = ["rust-analyzer", "copilot"]
  '';
in
{
  environment.systemPackages = with pkgs; [
    bossa-arduino
    arduino-language-server-rc
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
   platformio-core
   platformio-core.udev 
    zls
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
  copilotLsp = copilotLsp;
}
