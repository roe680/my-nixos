{
  pkgs,
  lib,
  username,
  ...
}:
{
  environment.systemPackages =
    with pkgs;
    [
      ccache
      python3
      python3Packages.pip
      python3Packages.virtualenv
      flex
      bison
      gperf
      wget
    ]
    ++ lib.optionals (pkgs ? espup) [ espup ]
    ++ lib.optionals (pkgs ? ldproxy) [ ldproxy ] # Rust (cargo) 系のフラッシャ
    ++ lib.optionals (pkgs ? espflash) [ espflash ]
    ++ lib.optionals (pkgs ? esp-idf) [ esp-idf ]
    ++ lib.optionals (pkgs ? openocd) [ openocd ]
    ++ lib.optionals (pkgs ? minicom) [ minicom ]
    ++ lib.optionals (pkgs ? picocom) [ picocom ];

  users.users.${username}.extraGroups = [ "dialout" ];
}
