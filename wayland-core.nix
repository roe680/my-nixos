{ pkgs, ... }:

{
  environment.sessionVariables = {
    STEAM_FORCE_DESKTOP_WM = "1";
    STEAM_WAYLAND = "1";
    LIBVA_DRIVER_NAME = "iHD"; # Arc は iHD ドライバーを明示指定
    ANV_VIDEO_DECOS = "1";
    GTK_USE_PORTAL = "1";
    EDITOR = "hx";
    NIXOS_OZONE_WL = "1";
    "LD" = "mold";
    # GCC/Clang に mold を使わせる
    NIX_LDFLAGS = "-fuse-ld=mold";
    # または
    LDFLAGS = "-fuse-ld=mold";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    GDK_BACKEND = "wayland,x11";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "niri";
    WINIT_UNIX_BACKEND = "wayland";
    # fcitx5
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
  };

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
      user = "greeter";
    };
  };

  environment.systemPackages = with pkgs; [
    tuigreet
    wayland-utils
    wlr-randr
    xdg-desktop-portal-gtk
    libva-utils
    vulkan-tools
  ];

  services.xserver.enable = false;
}
