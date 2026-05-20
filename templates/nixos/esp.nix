{
  pkgs,
  lib,
  username,
  ...
}:
{
  environment.systemPackages =
    with pkgs;
    [ ]
    # Rust (cargo) 系のフラッシャ
    ++ lib.optionals (pkgs ? espflash) [ espflash ]
    ++ lib.optionals (pkgs ? cargo-espflash) [ cargo-espflash ]
    ++ lib.optionals (pkgs ? esp-idf) [ esp-idf ]
    ++ lib.optionals (pkgs ? openocd) [ openocd ]
    ++ lib.optionals (pkgs ? minicom) [ minicom ]
    ++ lib.optionals (pkgs ? picocom) [ picocom ];

  services.udev.extraRules = ''
    # CP210x (Silabs) USB-to-UART
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="10c4", MODE:="0666", GROUP="dialout"
    # CH340 (QinHeng) USB-to-UART
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="1a86", MODE:="0666", GROUP="dialout"
    # Espressif USB JTAG/Serial (ESP32-S3 など)
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="303a", MODE:="0666", GROUP="dialout"
  '';

  users.users.${username}.extraGroups = [ "dialout" ];
}
