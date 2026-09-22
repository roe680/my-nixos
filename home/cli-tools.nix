{ pkgs, ... }:

{
  programs.eza = {
    enable = true;
    enableNushellIntegration = true;
    icons = "auto";
    git = true;
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "gruvbox-dark";
      style = "numbers,changes,header";
    };
  };

  programs.fd.enable = true;
  programs.ripgrep.enable = true;
  programs.fzf = {
    enable = true;
    historyWidget.nushell.command = "";
  };

  programs.yazi = {
    enable = true;
    enableNushellIntegration = true;
    shellWrapperName = "yy";
  };
  xdg.configFile."yazi/yazi.toml".source = (pkgs.formats.toml { }).generate "yazi.toml" {
    mgr = {
      show_hidden = false;
      sort_by = "natural";
    };
    preview = {
      image_filter = "nearest";
    };
  };
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      syntax-theme = "gruvbox-dark";
    };
  };

  programs.btop = {
    enable = true;
  };

  home.packages = with pkgs; [
    copilot-language-server
    usbutils
    # ファイル操作
    fastfetch
    lazygit
    ripgrep-all
    broot
    tree
    trash-cli
    ouch

    # Yazi 依存
    ffmpeg
    ffmpegthumbnailer
    p7zip
    jq
    poppler
    resvg
    imagemagick
    chafa
    ueberzugpp
    fish

    # 差分・編集
    difftastic
    sad
    (lib.hiPrio sd)
    # システム監視
    procs
    duf
    dust
    hyperfine
    bandwhich
    tokei

    # ネットワーク
    xh
    doggo
    websocat
    nmap
    mtr

    # データ処理
    yq-go
    qsv
    visidata

    # ユーティリティ
    asciinema
    magic-wormhole
    qrencode
    aichat
    tealdeer
    opencode
    pipx
    ydotool
    home-manager
    pulseaudio
    bc
    file
  ];
}
