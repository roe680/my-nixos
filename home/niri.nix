{
  inputs,
  pkgs,
  config,
  ...
}:

{

  programs.niri = {
    enable = true;
    package = pkgs.niri;
    settings = {
      prefer-no-csd = true;
      input = {
        keyboard.xkb.layout = "jp";
        touchpad = {
          tap = true;
          natural-scroll = true;
        };
      };
      outputs = {
        "eDP-1" = {
          scale = 1.25;
        };
      };
      # Noctalia-shell を起動

      spawn-at-startup = [
        { command = [ "noctalia-shell" ]; }
        {
          command = [
            "dbus-update-activation-environment"
            "--systemd"
            "WAYLAND_DISPLAY"
            "XDG_CURRENT_DESKTOP"
          ];
        }
        {
          command = [
            "rclone"
            "mount"
            "roe-google-drive:"
            "/home/YOUR_USER/gdrive_folder"
            "--vfs-cache-mode"
            "writes"
          ];
        }
        {
          command = [
            "rclone"
            "mount"
            "roe-google-photo:"
            "/home/YOUR_USER/gphoto_folder"
            "--vfs-cache-mode"
            "writes"
          ];
        }
      ];
      # レイアウト設定 (エラー修正済み)
      layout = {
        gaps = 16;
        center-focused-column = "never";
        preset-column-widths = [
          { proportion = 0.33333; }
          { proportion = 0.5; }
          { proportion = 0.66667; }
        ];
        default-column-width = {
          proportion = 0.5;
        };

        focus-ring = {
          enable = true;
          width = 4;
          active = {
            color = "#7fc8ff";
          };
          inactive = {
            color = "#505050";
          };
        };

        shadow = {
          enable = true; # shadow.on から修正
          softness = 30;
          spread = 5;
          offset = {
            x = 0;
            y = 5;
          };
          color = "#0007";
        };
      };

      binds = {
        # --- 基本 & アプリ起動 ---
        "Mod+Shift+Slash".action.show-hotkey-overlay = { };
        "Mod+T".action.spawn = [ "alacritty" ];
        "Mod+D".action.spawn = [ "walker" ];
        "Mod+Shift+D".action.spawn = [
          "walker"
          "--modules"
          "dmenu"
        ];
        "Super+Alt+L".action.spawn = [ "swaylock" ];
        "Mod+Q".action.close-window = { };
        "Mod+Shift+E".action.quit = { };

        # --- ASUS Zenbook メディアキー (3段階サイクル含む) ---
        "XF86AudioRaiseVolume".action.spawn = [
          "wpctl"
          "set-volume"
          "-l"
          "1.0"
          "@DEFAULT_AUDIO_SINK@"
          "0.02+"
        ];
        "XF86AudioLowerVolume".action.spawn = [
          "wpctl"
          "set-volume"
          "@DEFAULT_AUDIO_SINK@"
          "0.02-"
        ];
        "XF86AudioMute".action.spawn = [
          "wpctl"
          "set-mute"
          "@DEFAULT_AUDIO_SINK@"
          "toggle"
        ];
        "XF86AudioMicMute".action.spawn = [
          "wpctl"
          "set-mute"
          "@DEFAULT_AUDIO_SOURCE@"
          "toggle"
        ];
        "XF86MonBrightnessUp".action.spawn = [
          "sh"
          "-c"
          "brightnessctl set +5%"
        ];
        "XF86MonBrightnessDown".action.spawn = [
          "sh"
          "-c"
          "brightnessctl set 5%-"
        ];
        "XF86KbdBrightnessUp".action.spawn-sh = ''
          dev="asus::kbd_backlight"

          current=$(${pkgs.brightnessctl}/bin/brightnessctl -d "$dev" g)
          max=$(${pkgs.brightnessctl}/bin/brightnessctl -d "$dev" m)

          # 割合に変換（0〜100）
          percent=$(( current * 100 / max ))

          if [ "$percent" -eq 0 ]; then
            ${pkgs.brightnessctl}/bin/brightnessctl -d "$dev" set $(( max * 33 / 100 ))
          elif [ "$percent" -lt 50 ]; then
            ${pkgs.brightnessctl}/bin/brightnessctl -d "$dev" set $(( max * 67 / 100 ))
          elif [ "$percent" -lt 100 ]; then
            ${pkgs.brightnessctl}/bin/brightnessctl -d "$dev" set "$max"
          else
            ${pkgs.brightnessctl}/bin/brightnessctl -d "$dev" set 0
          fi
        '';
        # --- ナビゲーション (HJKL & 矢印) ---
        "Mod+H".action.focus-column-left = { };
        "Mod+J".action.focus-window-down = { };
        "Mod+K".action.focus-window-up = { };
        "Mod+L".action.focus-column-right = { };
        "Mod+Left".action.focus-column-left = { };
        "Mod+Right".action.focus-column-right = { };
        "Mod+Up".action.focus-window-up = { };
        "Mod+Down".action.focus-window-down = { };

        # --- リサイズ & 拡大 (Super + Plus/Minus/Equal) ---
        "Mod+Minus".action.set-column-width = "-10%";
        "Mod+Equal".action.set-column-width = "+10%";
        "Mod+Plus".action.set-column-width = "+10%";
        "Mod+Shift+Minus".action.set-window-height = "-10%";
        "Mod+Shift+Equal".action.set-window-height = "+10%";
        "Mod+Shift+Plus".action.set-window-height = "+10%";

        # --- Niri 特有操作 ---
        "Mod+R".action.switch-preset-column-width = { };
        "Mod+Shift+R".action.reset-window-height = { };
        "Mod+W".action.toggle-column-tabbed-display = { };
        "Mod+F".action.maximize-column = { };
        "Mod+Shift+F".action.fullscreen-window = { };
        "Mod+M".action.maximize-window-to-edges = { };
        "Mod+C".action.center-column = { };
        "Mod+O".action.toggle-overview = { };

        # --- フローティング ---
        "Mod+V".action.toggle-window-floating = { };
        "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = { };

        # --- カラム操作 (統合・排出) ---
        "Mod+Comma".action.consume-window-into-column = { };
        "Mod+Period".action.expel-window-from-column = { };
        "Mod+U".action.consume-window-into-column = { }; # あなたの追加分
        "Mod+I".action.expel-window-from-column = { }; # あなたの追加分
        "Mod+BracketLeft".action.consume-or-expel-window-left = { };
        "Mod+BracketRight".action.consume-or-expel-window-right = { };

        # --- ワークスペース (1-9) ---
        "Mod+1".action.focus-workspace = 1;
        "Mod+2".action.focus-workspace = 2;
        "Mod+3".action.focus-workspace = 3;
        "Mod+4".action.focus-workspace = 4;
        "Mod+5".action.focus-workspace = 5;
        "Mod+6".action.focus-workspace = 6;
        "Mod+7".action.focus-workspace = 7;
        "Mod+8".action.focus-workspace = 8;
        "Mod+9".action.focus-workspace = 9;

        # --- システム & スクリーンショット ---
        "Print".action.screenshot = { };
        "Ctrl+Print".action.screenshot-screen = { };
        "Alt+Print".action.screenshot-window = { };
        "Mod+Escape".action.toggle-keyboard-shortcuts-inhibit = { };
        "Mod+Shift+P".action.power-off-monitors = { };
        # --- カラム移動（デフォルト未バインド枠） ---
        "Mod+Shift+H".action.move-column-left = { };
        "Mod+Shift+L".action.move-column-right = { };

        # --- ワークスペース上下移動（デフォルト未バインド枠） ---
        "Mod+Page_Down".action.focus-workspace-down = { };
        "Mod+Page_Up".action.focus-workspace-up = { };

        # --- カラムをワークスペースへ移動 ---
        "Mod+Shift+Page_Down".action.move-column-to-workspace-down = { };
        "Mod+Shift+Page_Up".action.move-column-to-workspace-up = { };

        # --- Overview（デフォルトは Super+0） ---
        "Mod+0".action.toggle-overview = { };

        # --- デフォルト系の代替（もし使いたいなら） ---
        "Mod+BracketLeft".action.consume-or-expel-window-left = { };
        "Mod+BracketRight".action.consume-or-expel-window-right = { };
      };
    };
  };
}
