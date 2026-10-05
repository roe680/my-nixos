{ pkgs, ... }:

{

  programs.helix = {
    enable = true;

    settings = {
      theme = "kaolin-valley-dark"; # お好みのテーマ（catppuccin, draculaなど）

      editor = {
        bufferline = "multiple"; # 複数バッファ時に上部に一覧表示
        line-number = "relative"; # 行番号を相対表示に
        cursorline = true; # 現在の行をハイライト
        auto-format = true; # 保存時に自動フォーマット
        idle-timeout = 200; # オートコンプリートなどの反応速度（ミリ秒）
        color-modes = true; # モードによって色を変える
        true-color = true; # 24bitカラーを有効化
        undercurl = true; # アンダーカールを使用
        clipboard-provider = "wayland";

        lsp = {
          display-inlay-hints = true;
        };

        cursor-shape = {
          insert = "bar"; # インサートモード時は棒状
          normal = "block"; # ノーマルモード時はブロック
          select = "underline"; # 選択モード時は下線
        };

        file-picker = {
          hidden = true; # ドットファイルも検索対象にする
        };

        statusline = {
          left = [
            "mode"
            "file-type"
            "separator"
            "file-name"
            "file-modification-indicator"
            "read-only-indicator"
            "separator"
          ];
          right = [
            "version-control"
            "separator"
            "diagnostics"
            "separator"
            "position"
            "position-percentage"
          ];
          separator = " ";
          mode = {
            normal = " NORMAL ";
            insert = " INSERT ";
            select = " SELECT ";
          };
          diagnostics = [
            "error"
            "warning"
            "info"
            "hint"
          ];
        };

        inline-diagnostics = {
          cursor-line = "warning"; # カーソル行のみ warning 以上をインライン表示
          other-lines = "disable"; # 他行はノイズ防止で非表示
        };

        indent-guides = {
          render = true; # インデントの縦線を表示
          character = "╎"; # 縦線の文字
        };

        auto-save = {
          focus-lost = true;
          after-delay = {
            enable = true;
          };
        };
      };

      keys = {
        normal = {
          esc = [
            "collapse_selection"
            "keep_primary_selection"
          ];

          # スペースキーバインド
          space = {
            q = ":quit";
            o = "file_picker_in_current_buffer_directory";
            b = "buffer_picker";
          };

          # バッファ操作
          "A-w" = ":buffer-close";
          tab = ":buffer-next";
          "S-tab" = ":buffer-previous";

          # 行の移動・並び替え
          "C-k" = [
            "extend_to_line_bounds"
            "delete_selection"
            "move_line_up"
            "paste_before"
          ];
          "C-j" = [
            "extend_to_line_bounds"
            "delete_selection"
            "paste_after"
          ];

          # 行頭・行末ジャンプ
          H = [ "goto_line_start" ];
          L = [ "goto_line_end" ];

          # 行選択の改善
          "A-x" = "extend_to_line_bounds";
          X = "select_line_above";

          # トグル系
          "+" = {
            w = ":toggle whitespace.render all";
            s = ":toggle soft-wrap.enable";
            f = ":format";
          };
        };

        select = {
          H = [ "goto_line_start" ];
          L = [ "goto_line_end" ];
          "A-x" = "extend_to_line_bounds";
          X = "select_line_above";
        };

        insert = {
          j = {
            k = "normal_mode";
          };
        };
      };
    };

    languages = {
      language-server = {
        arduino-language-server = {
          command = "arduino-language-server";
          args = [
            "-fqbn"
            "arduino:avr:uno"
          ];
          # arduino-cli / clangd はPATH上から自動検出されるので
          # -cli や -clangd を明示しなくてもログにあった通り動くはず
          # ~/.arduino15/arduino-cli.yaml も自動検出済み
        };

        # --- GitHub Copilot LSP（バイナリは既に別モジュールでインストール済み） ---
        copilot = {
          command = "copilot-language-server";
          args = [ "--stdio" ];
          config = {
            editor.name = "helix";
            editor.version = "24.0";
            editorPlugin.name = "helix-copilot";
            editorPlugin.version = "0.1.0";
          };
        };
      };

      language = [
        {
          name = "ino";
          scope = "source.ino";
          file-types = [ "ino" ];
          grammar = "cpp"; # cppのtree-sitter文法を流用(inoグラマーは存在しないため)
          language-servers = [ "arduino-language-server" ];
          comment-token = "//";
          roots = [ ".ino-root" ];
          indent = {
            tab-width = 2;
            unit = "  ";
          };
        }

        # --- 既定の language-servers を維持しつつ copilot を追加 ---
        {
          name = "zig";
          language-servers = [ "zls" "copilot" ];
        }
        {
          name = "c";
          language-servers = [ "clangd" "copilot" ];
        }
        {
          name = "cpp";
          language-servers = [ "clangd" "copilot" ];
        }
        {
          name = "rust";
          language-servers = [ "rust-analyzer" "copilot" ];
        }
      ];
    };

  };

  home.file.".config/helix/runtime/queries/ino/highlights.scm".text = "; inherits: cpp";
  home.file.".config/helix/runtime/queries/ino/indents.scm".text = "; inherits: cpp";
  home.file.".config/helix/runtime/queries/ino/textobjects.scm".text = "; inherits: cpp";

  home.packages = with pkgs; [
    # LSP
    nil
    nixd
    slint-lsp
    #slint tool
    slint-viewer
  ];
}
