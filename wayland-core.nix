{ pkgs, ... }:
let
  fzfPreview = pkgs.writeShellScript "fzf-preview" ''
    TARGET="$1"
    if [ -d "$TARGET" ]; then
      ${pkgs.tree}/bin/tree -C "$TARGET" | head -n 100
      exit 0
    fi
    EXT=$(echo "''${TARGET##*.}" | tr '[:upper:]' '[:lower:]')
    case "$EXT" in
      zip) ${pkgs.p7zip}/bin/7z l "$TARGET" || ${pkgs.unzip}/bin/unzip -l "$TARGET" 2>/dev/null ;;
      tar|tgz|gz|bz2|xz) ${pkgs.gnutar}/bin/tar -tf "$TARGET" 2>/dev/null | head -n 100 ;;
      png|jpg|jpeg|gif|pdf|exe|elf) ${pkgs.file}/bin/file "$TARGET" ;;
      *)
        if ${pkgs.file}/bin/file "$TARGET" | grep -q text; then
          ${pkgs.bat}/bin/bat --style=numbers --color=always --line-range :500 "$TARGET"
        else
          ${pkgs.file}/bin/file "$TARGET"
        fi ;;
    esac
  '';
in
{
  environment.sessionVariables = {
    FZF_DEFAULT_OPTS =
      "--layout=reverse --height=60% --border --info=inline "
      + "--color 'bg+:#313244,spinner:#f5e0dc,hl:#f38ba8,fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc,marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8,border:#89b4fa' "
      + "--preview '${fzfPreview} {}'";

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

  networking.firewall.trustedInterfaces = [ "waydroid0" ];
  virtualisation.waydroid = {
    enable = true;
    package = pkgs.waydroid-nftables;
  };

  environment.systemPackages = with pkgs; [
    xorg.xhost
    tuigreet
    wayland-utils
    wlr-randr
    xdg-desktop-portal-gtk
    libva-utils
    vulkan-tools
  ];

  services.xserver.enable = false;
}
