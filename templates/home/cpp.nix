{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gcc
    gdb
    lldb
    cmake
    ninja
  ];
}
