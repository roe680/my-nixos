{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gcc
    bear
    gdb
    lldb
    cmake
    ninja
  ];
}
