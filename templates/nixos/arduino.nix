{ pkgs ? import <nixpkgs> {}, username ? "roe", ... }: # ← 末尾に `...` を追加して未知の引数を許容
let
  # arduino-language-server の stderr から非 UTF-8 バイトを除去するラッパー
  arduinoLspWrapped = pkgs.writeShellScriptBin "arduino-language-server-wrapped" ''
    #!${pkgs.bash}/bin/bash
    exec ${pkgs.arduino-language-server}/bin/arduino-language-server "$@" 2> >(${pkgs.glibc}/bin/iconv -c -f UTF-8 -t UTF-8 >&2)
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
      "-clangd", "${pkgs.llvmPackages_18.clang-tools}/bin/clangd",
      "-fqbn", "arduino:avr:uno"
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
  ];

  users.groups.plugdev = { };
  users.users.${username}.extraGroups = [
    "dialout"
    "plugdev"
  ];

  helix.languagesToml = helixLanguagesToml;
}
