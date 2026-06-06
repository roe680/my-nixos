{ pkgs, username, ... }:
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
  ];

  # ② plugdev グループを明示的に作成
  users.groups.plugdev = { };

  users.users.${username}.extraGroups = [
    "dialout"
    "plugdev"
  ];
}
