{pkgs, username, ...} : {
  environment.systemPackages = with pkgs; [
    bossa-arduino
    arduino-language-server
    arduino-cli
    arduino-ide
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
  ];

  # ① probe-rs の udev ルールをパッケージから自動追加
  services.udev.packages = [ pkgs.probe-rs-tools ];

  services.udev.extraRules = ''
    # Arduino Uno / Mega 2560 など
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2341", MODE:="0666", GROUP="plugdev"
    # 一般的なUSBシリアル変換チップ (CH340など)
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="1a86", MODE:="0666", GROUP="plugdev"
    # Arduino Uno R4 Minima (通常モード)
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="0069", MODE:="0666", GROUP="plugdev"
    # Arduino Uno R4 Minima (ブートローダーモード)
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="006d", MODE:="0666", GROUP="plugdev"
  '';

  # ② plugdev グループを明示的に作成
  users.groups.plugdev = {};

  users.users.${username}.extraGroups = [ "dialout" "plugdev" ];
}
