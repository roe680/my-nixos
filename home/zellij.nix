{ inputs, pkgs, ... }:
{
  programs.zellij = {
    extraConfig = ''
      pane_viewport_serialization true
        // ── テーマ定義 (KDL config より) ──

        themes {
            my-theme {
                frame_unselected {
                    base "#181825"
                    background 0
                    emphasis_0 0
                    emphasis_1 0
                    emphasis_2 0
                    emphasis_3 0
                }
                frame_selected {
                    base "#89B4FA"
                    background 0
                    emphasis_0 0
                    emphasis_1 0
                    emphasis_2 0
                    emphasis_3 0
                }
                frame_highlight {
                    base "#9399B2"
                    background 0
                    emphasis_0 0
                    emphasis_1 0
                    emphasis_2 0
                    emphasis_3 0
                }
            }
        }

        // ── キーバインド (KDL config より) ──
        keybinds {
            normal {
                // uncomment this and adjust key if using copy_on_select=false
                // bind "Alt c" { Copy; }
            }
            locked {
                bind "Ctrl g" { SwitchToMode "Normal"; }
            }
            resize {
                bind "Ctrl n" { SwitchToMode "Normal"; }
                bind "h" "Left" { Resize "Increase Left"; }
                bind "j" "Down" { Resize "Increase Down"; }
                bind "k" "Up" { Resize "Increase Up"; }
                bind "l" "Right" { Resize "Increase Right"; }
                bind "H" { Resize "Decrease Left"; }
                bind "J" { Resize "Decrease Down"; }
                bind "K" { Resize "Decrease Up"; }
                bind "L" { Resize "Decrease Right"; }
                bind "=" "+" { Resize "Increase"; }
                bind "-" { Resize "Decrease"; }
            }
            pane {
                bind "Ctrl p" { SwitchToMode "Normal"; }
                bind "h" "Left" { MoveFocus "Left"; }
                bind "l" "Right" { MoveFocus "Right"; }
                bind "j" "Down" { MoveFocus "Down"; }
                bind "k" "Up" { MoveFocus "Up"; }
                bind "p" { SwitchFocus; }
                bind "n" { NewPane; SwitchToMode "Normal"; }
                bind "d" { NewPane "Down"; SwitchToMode "Normal"; }
                bind "r" { NewPane "Right"; SwitchToMode "Normal"; }
                bind "s" { NewPane "stacked"; SwitchToMode "Normal"; }
                bind "x" { CloseFocus; SwitchToMode "Normal"; }
                bind "f" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
                bind "z" { TogglePaneFrames; SwitchToMode "Normal"; }
                bind "w" { ToggleFloatingPanes; SwitchToMode "Normal"; }
                bind "e" { TogglePaneEmbedOrFloating; SwitchToMode "Normal"; }
                bind "c" { SwitchToMode "RenamePane"; PaneNameInput 0;}
                bind "i" { TogglePanePinned; SwitchToMode "Normal"; }
            }
            move {
                bind "Ctrl h" { SwitchToMode "Normal"; }
                bind "n" "Tab" { MovePane; }
                bind "p" { MovePaneBackwards; }
                bind "h" "Left" { MovePane "Left"; }
                bind "j" "Down" { MovePane "Down"; }
                bind "k" "Up" { MovePane "Up"; }
                bind "l" "Right" { MovePane "Right"; }
            }
            tab {
                bind "Ctrl t" { SwitchToMode "Normal"; }
                bind "r" { SwitchToMode "RenameTab"; TabNameInput 0; }
                bind "h" "Left" "Up" "k" { GoToPreviousTab; }
                bind "l" "Right" "Down" "j" { GoToNextTab; }
                bind "n" { NewTab; SwitchToMode "Normal"; }
                bind "x" { CloseTab; SwitchToMode "Normal"; }
                bind "s" { ToggleActiveSyncTab; SwitchToMode "Normal"; }
                bind "b" { BreakPane; SwitchToMode "Normal"; }
                bind "]" { BreakPaneRight; SwitchToMode "Normal"; }
                bind "[" { BreakPaneLeft; SwitchToMode "Normal"; }
                bind "1" { GoToTab 1; SwitchToMode "Normal"; }
                bind "2" { GoToTab 2; SwitchToMode "Normal"; }
                bind "3" { GoToTab 3; SwitchToMode "Normal"; }
                bind "4" { GoToTab 4; SwitchToMode "Normal"; }
                bind "5" { GoToTab 5; SwitchToMode "Normal"; }
                bind "6" { GoToTab 6; SwitchToMode "Normal"; }
                bind "7" { GoToTab 7; SwitchToMode "Normal"; }
                bind "8" { GoToTab 8; SwitchToMode "Normal"; }
                bind "9" { GoToTab 9; SwitchToMode "Normal"; }
                bind "Tab" { ToggleTab; }
            }
            scroll {
                bind "Ctrl s" { SwitchToMode "Normal"; }
                bind "e" { EditScrollback; SwitchToMode "Normal"; }
                bind "s" { SwitchToMode "EnterSearch"; SearchInput 0; }
                bind "Ctrl c" { ScrollToBottom; SwitchToMode "Normal"; }
                bind "j" "Down" { ScrollDown; }
                bind "k" "Up" { ScrollUp; }
                bind "Ctrl f" "PageDown" "Right" "l" { PageScrollDown; }
                bind "Ctrl b" "PageUp" "Left" "h" { PageScrollUp; }
                bind "d" { HalfPageScrollDown; }
                bind "u" { HalfPageScrollUp; }
                // uncomment this and adjust key if using copy_on_select=false
                // bind "Alt c" { Copy; }
            }
            search {
                bind "Ctrl s" { SwitchToMode "Normal"; }
                bind "Ctrl c" { ScrollToBottom; SwitchToMode "Normal"; }
                bind "j" "Down" { ScrollDown; }
                bind "k" "Up" { ScrollUp; }
                bind "Ctrl f" "PageDown" "Right" "l" { PageScrollDown; }
                bind "Ctrl b" "PageUp" "Left" "h" { PageScrollUp; }
                bind "d" { HalfPageScrollDown; }
                bind "u" { HalfPageScrollUp; }
                bind "n" { Search "down"; }
                bind "p" { Search "up"; }
                bind "c" { SearchToggleOption "CaseSensitivity"; }
                bind "w" { SearchToggleOption "Wrap"; }
                bind "o" { SearchToggleOption "WholeWord"; }
            }
            entersearch {
                bind "Ctrl c" "Esc" { SwitchToMode "Scroll"; }
                bind "Enter" { SwitchToMode "Search"; }
            }
            renametab {
                bind "Ctrl c" { SwitchToMode "Normal"; }
                bind "Esc" { UndoRenameTab; SwitchToMode "Tab"; }
            }
            renamepane {
                bind "Ctrl c" { SwitchToMode "Normal"; }
                bind "Esc" { UndoRenamePane; SwitchToMode "Pane"; }
            }

            session {
                bind "Ctrl o" { SwitchToMode "Normal"; }
                bind "Ctrl s" { SwitchToMode "Scroll"; }
                bind "d" { Detach; }
                bind "w" {
                    LaunchOrFocusPlugin "session-manager" {
                        floating true
                        move_to_focused_tab true
                    };
                    SwitchToMode "Normal"
                }
                bind "c" {
                    LaunchOrFocusPlugin "configuration" {
                        floating true
                        move_to_focused_tab true
                    };
                    SwitchToMode "Normal"
                }
                bind "p" {
                    LaunchOrFocusPlugin "plugin-manager" {
                        floating true
                        move_to_focused_tab true
                    };
                    SwitchToMode "Normal"
                }
                bind "a" {
                    LaunchOrFocusPlugin "zellij:about" {
                        floating true
                        move_to_focused_tab true
                    };
                    SwitchToMode "Normal"
                }
                bind "s" {
                    LaunchOrFocusPlugin "zellij:share" {
                        floating true
                        move_to_focused_tab true
                    };
                    SwitchToMode "Normal"
                }
                bind "l" {
                    LaunchOrFocusPlugin "zellij:layout-manager" {
                        floating true
                        move_to_focused_tab true
                    };
                    SwitchToMode "Normal"
                }
            }
            tmux {
                bind "[" { SwitchToMode "Scroll"; }
                bind "Ctrl b" { Write 2; SwitchToMode "Normal"; }
                bind "\"" { NewPane "Down"; SwitchToMode "Normal"; }
                bind "%" { NewPane "Right"; SwitchToMode "Normal"; }
                bind "z" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
                bind "c" { NewTab; SwitchToMode "Normal"; }
                bind "," { SwitchToMode "RenameTab"; }
                bind "p" { GoToPreviousTab; SwitchToMode "Normal"; }
                bind "n" { GoToNextTab; SwitchToMode "Normal"; }
                bind "Left" { MoveFocus "Left"; SwitchToMode "Normal"; }
                bind "Right" { MoveFocus "Right"; SwitchToMode "Normal"; }
                bind "Down" { MoveFocus "Down"; SwitchToMode "Normal"; }
                bind "Up" { MoveFocus "Up"; SwitchToMode "Normal"; }
                bind "h" { MoveFocus "Left"; SwitchToMode "Normal"; }
                bind "l" { MoveFocus "Right"; SwitchToMode "Normal"; }
                bind "j" { MoveFocus "Down"; SwitchToMode "Normal"; }
                bind "k" { MoveFocus "Up"; SwitchToMode "Normal"; }
                bind "o" { FocusNextPane; }
                bind "d" { Detach; }
                bind "Space" { NextSwapLayout; }
                bind "x" { CloseFocus; SwitchToMode "Normal"; }
            }
            shared_except "locked" {
                bind "Ctrl g" { SwitchToMode "Locked"; }
                bind "Ctrl q" { Quit; }
                bind "Alt f" { ToggleFloatingPanes; }
                bind "Alt n" { NewPane; }
                bind "Alt i" { MoveTab "Left"; }
                bind "Alt o" { MoveTab "Right"; }
                bind "Alt h" "Alt Left" { MoveFocusOrTab "Left"; }
                bind "Alt l" "Alt Right" { MoveFocusOrTab "Right"; }
                bind "Alt j" "Alt Down" { MoveFocus "Down"; }
                bind "Alt k" "Alt Up" { MoveFocus "Up"; }
                bind "Alt =" "Alt +" { Resize "Increase"; }
                bind "Alt -" { Resize "Decrease"; }
                bind "Alt [" { PreviousSwapLayout; }
                bind "Alt ]" { NextSwapLayout; }
                bind "Alt p" { TogglePaneInGroup; }
                bind "Alt Shift p" { ToggleGroupMarking; }
            }
            shared_except "normal" "locked" {
                bind "Enter" "Esc" { SwitchToMode "Normal"; }
            }
            shared_except "pane" "locked" {
                bind "Ctrl p" { SwitchToMode "Pane"; }
            }
            shared_except "resize" "locked" {
                bind "Ctrl n" { SwitchToMode "Resize"; }
            }
            shared_except "scroll" "locked" {
                bind "Ctrl s" { SwitchToMode "Scroll"; }
            }
            shared_except "session" "locked" {
                bind "Ctrl o" { SwitchToMode "Session"; }
            }
            shared_except "tab" "locked" {
                bind "Ctrl t" { SwitchToMode "Tab"; }
            }
            shared_except "move" "locked" {
                bind "Ctrl h" { SwitchToMode "Move"; }
            }
            shared_except "tmux" "locked" {
                bind "Ctrl b" { SwitchToMode "Tmux"; }
            }
        }

        // ── web_client (KDL config より) ──
        web_client {
            font "monospace"
        }

        // ── zjstatus プラグインのバックグラウンド読み込み ──
        load_plugins {
          "file:${inputs.zjstatus.packages.${pkgs.system}.default}/bin/zjstatus.wasm"
        }
    '';

    enable = true;

    settings = {
      show_startup_tips = false;
      show_release_notes = false;
      welcome_screen = false; # これで起動時のメニューも消えます
      theme = "my-theme";
      default_shell = "nu";
      pane_frames = true;

      plugins = {
        tab-bar = {
          location = "zellij:tab-bar";
        };
        status-bar = {
          location = "zellij:status-bar";
        };
        strider = {
          location = "zellij:strider";
        };
        compact-bar = {
          location = "zellij:compact-bar";
        };
        session-manager = {
          location = "zellij:session-manager";
        };
        filepicker = {
          location = "zellij:strider";
          cwd = "/";
        };
        configuration = {
          location = "zellij:configuration";
        };
        plugin-manager = {
          location = "zellij:plugin-manager";
        };
        sequence = {
          location = "zellij:sequence";
        };
      };
    };

    # 元の nix 式からそのまま(キーバインドに完全対応させたステータスバー表示に更新)
    layouts = {
      default = ''
        layout {
            default_tab_template {
                pane size=1 borderless=true {
                    plugin location="file:${
                      inputs.zjstatus.packages.${pkgs.system}.default
                    }/bin/zjstatus.wasm" {
                        format_left  "#[bg=#89B4FA,fg=#181825,bold] {session} #[bg=#181825]{tabs}"
                        format_space "#[bg=#181825]"
                        tab_normal              "#[fg=#6C7086,bg=#181825] {index} {name} {fullscreen_indicator}{sync_indicator}{floating_indicator} #[fg=#424554,bold]"
                        tab_active   "#[bg=#9399B2,fg=#181825,bold,italic] {index} {name} {fullscreen_indicator}{sync_indicator}{floating_indicator} #[fg=#9399B2,bg=#181825,bold]"
                        tab_fullscreen_indicator "□ "
                        tab_sync_indicator       "  "
                        tab_floating_indicator   "󰉈 "
                    }
                }

                children

                pane size=1 borderless=true {
                    plugin location="file:${
                      inputs.zjstatus.packages.${pkgs.system}.default
                    }/bin/zjstatus.wasm" {
                        // 左側: 現在のモード固有のキー
                        format_left  "{mode}"
                        // 右側: 全モード共通(lockedを除く)のAlt系グローバルキー + kubectx/kubens/日時
                        format_right "#[bg=#181825,fg=#424554] A-f:float A-n:new A-hjkl:focus A-io:move-tab A-+/-:resize A-[/]:swap-layout A-p:group A-P:mark ^g:lock ^q:quit  {command_kubectx}#[fg=#424554,bg=#181825]::{command_kubens}{datetime}"
                        format_space "#[bg=#181825]"

                        // normal: shared_except "locked" の Ctrl+p/t/n/s/o/h/b に対応(全モード直接切替)
                        mode_normal "#[bg=#89B4FA,fg=#181825,bold] NORMAL #[bg=#181825,fg=#6C7086] ^p:pane ^t:tab ^n:resize ^s:scroll ^o:session ^h:move ^b:tmux "

                        // locked: Ctrl+g で解除。Alt系グローバルキーもここでは無効
                        mode_locked "#[bg=#FF5555,fg=#181825,bold] LOCKED #[bg=#181825,fg=#6C7086] ^g:unlock "

                        // resize: hjkl/HJKL 方向リサイズ、=/+ と - は全体増減、Ctrl+n で戻る
                        mode_resize "#[bg=#89B4FA,fg=#181825,bold] RESIZE #[bg=#181825,fg=#89B4FA] hjkl:grow HJKL:shrink =/+:incr -:decr ^n:normal "

                        // pane: s(stack)・i(pin)・p(switch focus)を追加、Ctrl+p で戻る
                        mode_pane "#[bg=#89B4FA,fg=#181825,bold] PANE #[bg=#181825,fg=#89B4FA] hjkl:focus p:switch n:new d:↓ r:→ s:stack x:close f:full w:float e:embed c:rename i:pin ^p:normal "

                        // tab: b(break)・[ ](break left/right)・Tab(toggle)を追加、Ctrl+t で戻る
                        mode_tab "#[bg=#89B4FA,fg=#181825,bold] TAB #[bg=#181825,fg=#89B4FA] h/l:prev/next n:new x:close r:rename 1-9:goto s:sync b:break []:break-l/r Tab:toggle ^t:normal "

                        // scroll: Ctrl+s で戻る
                        mode_scroll "#[bg=#89B4FA,fg=#181825,bold] SCROLL #[bg=#181825,fg=#89B4FA] jk:scroll ^f/^b:page d/u:half s:search e:edit ^s:normal "

                        mode_enter_search "#[bg=#89B4FA,fg=#181825,bold] SEARCH #[bg=#181825,fg=#89B4FA] Enter:search Esc:cancel "
                        mode_search       "#[bg=#89B4FA,fg=#181825,bold] SEARCH #[bg=#181825,fg=#89B4FA] n:↓ p:↑ c:case w:wrap o:word "

                        // renametab/renamepane: Esc は undo(元に戻す)、Ctrl+c でキャンセル終了
                        mode_rename_tab  "#[bg=#89B4FA,fg=#181825,bold] RENAME TAB #[bg=#181825,fg=#89B4FA] Enter:confirm Esc:undo ^c:cancel "
                        mode_rename_pane "#[bg=#89B4FA,fg=#181825,bold] RENAME PANE #[bg=#181825,fg=#89B4FA] Enter:confirm Esc:undo ^c:cancel "

                        // session: a(about)・s(share)・l(layout-manager)を追加、Ctrl+o で戻る
                        mode_session "#[bg=#89B4FA,fg=#181825,bold] SESSION #[bg=#181825,fg=#89B4FA] d:detach w:manager c:config p:plugins a:about s:share l:layout ^o:normal "

                        // move: Ctrl+h で戻る
                        mode_move "#[bg=#89B4FA,fg=#181825,bold] MOVE #[bg=#181825,fg=#89B4FA] hjkl:move n/Tab:next p:prev ^h:normal "

                        mode_prompt "#[bg=#89B4FA,fg=#181825,bold] PROMPT #[bg=#181825,fg=#89B4FA] "

                        // tmux: o(次のペイン)・space(レイアウト切替)・[(scrollへ)を追加、Ctrl+b で戻る
                        mode_tmux "#[bg=#ffc387,fg=#181825,bold] TMUX #[bg=#181825,fg=#89B4FA] c:new-tab \"/%%:split z:full ,:rename hjkl:focus o:next space:swap [:scroll x:close d:detach ^b:normal "

                        mode_default_to_mode "tmux"
                        command_kubectx_command  "kubectx -c"
                        command_kubectx_format   "#[fg=#6C7086,bg=#181825,italic] {stdout}"
                        command_kubectx_interval "2"
                        command_kubens_command   "kubens -c"
                        command_kubens_format    "#[fg=#6C7086,bg=#181825]{stdout} "
                        command_kubens_interval  "2"
                        datetime          "#[fg=#9399B2,bg=#181825] {format} "
                        datetime_format   "%A, %d %b %Y %H:%M"
                        datetime_timezone "Asia/Tokyo"
                    }
                }
            }
        }
      '';
    };
  };
}
