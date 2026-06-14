{
  pkgs,
  pkgs-stable,
  inputs,
  hostname,
  username,
  lib,
  ...
}:
{
  imports = [
    ./google.nix
    ./steam.nix
    ./niri.nix
    ./hardware-configuration.nix
    ./core.nix
    ./template.nix
    ./audio.nix
    ./bluetooth.nix
    ./docker.nix
    ./secrets.nix
  ];
  fileSystems."/mnt/usb" = {
    device = "/dev/sda1";
    fsType = "exfat";
    options = [
      "nofail"
      "uid=1000"
      "gid=100"
    ];
  };
  services.scx = {
    enable = true;
    scheduler = "scx_bpfland"; # Rust製低遅延スケジューラ
  };
  powerManagement.cpuFreqGovernor = "performance";
  services.power-profiles-daemon.enable = true;

  # 仮想カメラの動作安定化
  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 card_label="OBS Virtual Camera"
  '';
  # 1. カーネルパラメータで休止状態からの復旧を明示的にスキップ
  boot.kernelParams = [
    "noresume"
    "nvme_core.default_ps_max_latency_us=0" # NVMe APST無効化
    "pcie_aspm=off"
    "i915.force_probe=!7d51"
    "xe.force_probe=7d51"
    "asus_wmi.fnlock_default=1"
  ];
  # configuration.nix
  systemd.services.NetworkManager-wait-online.enable = false;
  services.udev.extraRules =
    let
      toggleScript = pkgs.writeShellScript "toggle-touchpad" ''
        for dev in /sys/class/input/input*; do
          if grep -q "ASUP1206:00 093A:300D Touchpad" "$dev/name"; then
            echo "$1" > "$dev/inhibited"
          fi
        done
      '';
    in
    ''
      # Logitechレシーバー（046d:c53f）が挿さったらタッチパッドOFF
      ACTION=="add", SUBSYSTEM=="usb", ENV{PRODUCT}=="46d/c53f/*", RUN+="${toggleScript} 1"

      # 抜いたらONに戻す
      ACTION=="remove", SUBSYSTEM=="usb", ENV{PRODUCT}=="46d/c53f/*", RUN+="${toggleScript} 0"

      # NVMe最適化
      ACTION=="add|change", KERNEL=="nvme*", ATTR{queue/scheduler}="kyber"
    '';
  services.upower.enable = true;
  services.dbus.enable = true;
  networking.hostName = hostname;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
      "audio"
      "video"
      "networkmanager"
      "input"
    ];
    shell = pkgs.nushell;
  };
  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];
  system.stateVersion = "24.11";
  xdg.portal = {
    enable = true;
    # niriはgnomeポータルと相性が良いため、wlrよりもgnomeを推奨
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk

    ];
    config = {
      common = {
        default = [ "gnome" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
    };
  };
}
