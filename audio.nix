{ pkgs,config, ... }:

{
  environment.systemPackages = with pkgs; [
    (wrapOBS {
      plugins = with obs-studio-plugins; [
        wlrobs # Wayland画面キャプチャ
        obs-pipewire-audio-capture
      ];
    })
    pavucontrol
  ];
   # 2. カーネルモジュールの設定
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  boot.kernelModules = [ "v4l2loopback" ];
    # 1. OBSのインストールと仮想カメラの有効化
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true; # これだけで必要なモジュールが自動設定されます
  };


  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  security.rtkit.enable = true;

}
