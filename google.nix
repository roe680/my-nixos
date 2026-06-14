{ pkgs, ... }:
{
  programs.fuse.userAllowOther = true;
  environment.systemPackages = [ pkgs.rclone ];
  boot.supportedFilesystems = [
    "fuse"
  ];
}
