{ pkgs, inputs, ... }:

{
  programs.alacritty = {
    enable = true;
    settings = {
      # 環境変数

      env.TERM = "alacritty";

      # ウィンドウ設定
      window = {
        opacity = 0.95;
        decorations = "None"; # バーが必要な場合はFull、不要ならNone
      };

      # フォント設定
      font = {
        size = 12.0;
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

      # シェル設定 (Nushell + Zellij自動起動)
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

  programs.ghostty = {
    enable = true;
    # デーモン（systemd ユーザーサービス）を有効化
    systemd.enable = true;

    settings = {
      # デーモンとして常駐させるための推奨設定
      gtk-single-instance = true;
      cursor-style = "bar";

      # 最後のウィンドウを閉じてもデーモンを維持する場合（任意）
      quit-after-last-window-closed = false;
    };
  };

  programs.nushell = {
    enable = true;
    extraConfig = ''
      $env.config.show_banner = false
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
}
