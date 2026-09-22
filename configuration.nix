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
  security.polkit = {
  enable = true;
  enablePkexecWrapper = true;
};
  services.udisks2.enable = true;
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
    inputs.noctalia-greeter.nixosModules.default

  ];
  programs.noctalia-greeter = {
  enable = true;

  greeter-args = "--session niri";
};
nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
  "copilot-language-server"
];
programs.noctalia-greeter.settings = {
  keyboard = {
    layout = "jp";
  };
};
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
  nixpkgs.config.permittedInsecurePackages = [
   "ventoy-gtk3-1.1.17"
];
services.displayManager.sessionPackages = [
  pkgs.niri
];
  powerManagement.cpuFreqGovernor = "performance";
  services.power-profiles-daemon.enable = true;

  # 【ここが重要】Ollamaの起動タイミングを「システム」ではなく「GPU側」に完全に委ねる
  systemd.services.ollama = {
    # デフォルトのシステム起動（multi-user.targetなど）の列からOllamaを外す
    wantedBy = lib.mkForce [ ];

    # その代わり、「GPU（card0）がシステムに完全に確定した瞬間」にだけ引っ掛けて起動させる
    bindsTo = [ "dev-dri-card0.device" ];
    after = [ "dev-dri-card0.device" ];
  };

  # Udev側から「GPUが確定したらOllamaを呼ぶ」というトリガーを仕込む
  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;

    environmentVariables = {
      OLLAMA_VULKAN = "1";
      OLLAMA_IGPU_ENABLE = "1"; # iGPUの除外を解除(必須)
      OLLAMA_NUM_PARALLEL = "1";
      OLLAMA_KEEP_ALIVE = "0";
      OLLAMA_KV_CACHE_TYPE = "q8_0";
    };
  };

  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 card_label="OBS Virtual Camera"
  '';
  # 1. カーネルパラメータで休止状態からの復旧を明示的にスキップ
  boot.kernelParams = [
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
      SUBSYSTEM=="drm", KERNEL=="card0", TAG+="systemd", ENV{SYSTEMD_WANTS}+="ollama.service"
        # Logitechレシーバー（046d:c53f）が挿さったらタッチパッドOFF
        ACTION=="add", SUBSYSTEM=="usb", ENV{PRODUCT}=="46d/c53f/*", RUN+="${toggleScript} 1"
        # 抜いたらONに戻す
        ACTION=="remove", SUBSYSTEM=="usb", ENV{PRODUCT}=="46d/c53f/*", RUN+="${toggleScript} 0"
        # Elecom M-G01UR（056e:0140）が挿さったらタッチパッドOFF
        ACTION=="add", SUBSYSTEM=="usb", ENV{PRODUCT}=="56e/140/*", RUN+="${toggleScript} 1"
        # 抜いたらONに戻す
        ACTION=="remove", SUBSYSTEM=="usb", ENV{PRODUCT}=="56e/140/*", RUN+="${toggleScript} 0"
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
  environment.shells = [ pkgs.nushell ];
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
