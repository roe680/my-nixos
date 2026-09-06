{
  config,
  pkgs,
  inputs,
  home,
  ...
}:

{
programs.ghostty = {
  enable = true;

  # systemd ユーザーサービス
  systemd.enable = true;

  settings = {
  font-feature = "calt";
    # 環境変数
    term = "xterm-ghostty";

    # ウィンドウ設定
    background-opacity = 0.95;
    window-decoration = "none";

    # フォント設定
    font-family = "UDEV Gothic 35NFLG";
    font-style = "Medium";
    font-size = 10.5;

    # カーソル設定
    cursor-style = "bar";
    cursor-style-blink = true;

    # スクロールバック
    scrollback-limit = 0;

    # Zellijを起動
    command = "zellij";

    # キーバインド
keybind = "ctrl+semicolon=increase_font_size:1";
    # カラー
    background = "000109";

    # シングルインスタンス
    gtk-single-instance = true;

    # 最後のウィンドウを閉じてもプロセスを終了しない
    quit-after-last-window-closed = false;
    confirm-close-surface = false;
  };
};
  
  
  programs.alacritty = {
    enable = true;
    settings = {
      # 環境変数

      env.TERM = "xterm-ghostty";

      # ウィンドウ設定
      window = {
        opacity = 0.95;
        decorations = "None"; # バーが必要な場合はFull、不要ならNone
      };

      # フォント設定
      font = {
        size = 10.5;
        normal = {
          family = "UDEV Gothic 35NF"; # Hack Nerd Fontからこちらに統合
          style = "Medium";
        };
      };

      # カーソル設定 (バー形状)
      cursor = {
        style = {
          shape = "Beam";
          blinking = "On";
        };
      };

      # スクロール設定 (Zellijに任せるため0)
      scrolling.history = 0;

      terminal.shell = {
        program = "zellij";
      };

      # キーバインド
      keyboard.bindings = [
        {
          key = "Semicolon";
          mods = "Control";
          action = "IncreaseFontSize";
        }
      ];

      # カラー設定
      colors.primary = {
        background = "#000109";
      };
    };
  };


  programs.nushell = {
    enable = true;
    extraConfig = ''
        $env.config.show_banner = false
          # config.nu に自動で追記される設定
      use "${config.home.homeDirectory}/.config/nushell/scripts/mod.nu" *
    '';
  };

  programs.starship = {
    enable = true;
    enableNushellIntegration = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$nix_shell$character";
      character = {
        success_symbol = "[❯](green)";
        error_symbol = "[❯](red)";
      };
    };
  };

  programs.carapace = {
    enable = true;
    enableNushellIntegration = true;
  };

  programs.atuin = {
    enable = true;
    enableNushellIntegration = true;
    settings = {
      style = "compact";
      search_mode = "fuzzy";
      filter_mode = "directory";
    };
  };

  programs.zoxide = {
    enable = true;
    enableNushellIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableNushellIntegration = true;
    nix-direnv.enable = true;
  };
  home.packages = with pkgs; [ nix-direnv ];
}
