{
  pkgs,
  lib,
  username,
  ...
}:
let
  espToolchain = "/home/${username}/.rustup/toolchains/esp";
in
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
    ++ lib.optionals (pkgs ? ldproxy) [ ldproxy ]
    ++ lib.optionals (pkgs ? espflash) [ espflash ]
    ++ lib.optionals (pkgs ? esp-idf) [ esp-idf ]
    ++ lib.optionals (pkgs ? openocd) [ openocd ]
    ++ lib.optionals (pkgs ? minicom) [ minicom ]
    ++ lib.optionals (pkgs ? picocom) [ picocom ];

  environment.sessionVariables = {
    LIBCLANG_PATH = "${espToolchain}/xtensa-esp32-elf-clang/esp-20.1.1_20250829/esp-clang/lib";
  };

  environment.extraInit = ''
    export PATH="${espToolchain}/xtensa-esp-elf/esp-15.2.0_20250920/xtensa-esp-elf/bin:$PATH"
  '';

  users.users.${username}.extraGroups = [ "dialout" ];
}
