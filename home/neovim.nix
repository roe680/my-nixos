# neovim.nix
# home-manager の programs.neovim に組み込むHelix風設定。
# home.nix 等で `imports = [ ./neovim.nix ];` するか、中身をマージしてください。
#
# 設計方針:
#   - lazy.nvim は使わない (Nixが既にプラグインをビルド/配置済みなので不要かつ
#     起動時 git clone は宣言的管理と衝突する)
#   - mason.nvim も使わない (LSPサーバーは extraPackages を通じてNixで供給する。
#     Nixとmasonの二重管理を避けるため)
#   - プラグインは全て pkgs.vimPlugins.* から取得し、
#     設定(setup呼び出し・キーマップ)は extraLuaConfig にまとめる
{ pkgs, lib, ... }:

let
  # AniMotion.nvim は小規模プラグインでnixpkgs未収録の可能性が高いため自前ビルド。
  # 初回 `home-manager switch` (または `nix build`) 時にハッシュ不一致のエラーが出るので、
  # エラーメッセージに表示される "got: sha256-....." の値を下の sha256 に貼り替えてください。
  animotion-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "AniMotion.nvim";
    version = "unstable-2026-09";
    src = pkgs.fetchFromGitHub {
      owner = "luiscassih";
      repo = "AniMotion.nvim";
      rev = "main"; # 再現性のためできれば特定のコミットハッシュに固定してください
      sha256 = "sha256-Ro+Nic4v2oR60p/rE3vm0iDCNU+EtkSKAiTHkp19WB8=";
    };
  };
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = false;
    vimAlias = true;
    withRuby = true;
    withPython3 = true;

    extraPackages = with pkgs; [
      lazygit
      ripgrep
      fd
      gcc
      nodejs

      # LSPサーバー本体をNixから供給する (mason.nvimは使わない方針)
      lua-language-server
      # 使う言語に応じて追加してください。例:
      # nil                 # Nix
      # pyright             # Python
      # rust-analyzer       # Rust
      # nodePackages.typescript-language-server
    ];

    plugins = with pkgs.vimPlugins; [
      # --- Helixの「選択→操作」モデル本体 ---
      animotion-nvim

      # --- マルチカーソル ---
      multicursor-nvim

      # --- カラースキーム ---
      catppuccin-nvim

      # --- Treesitter (全パーサー同梱。ランタイムでのgccコンパイルは不要) ---
      (nvim-treesitter.withAllGrammars)
      nvim-treesitter-textobjects

      # --- LSP ---
      nvim-lspconfig

      # --- 補完 ---
      nvim-cmp
      cmp-nvim-lsp
      luasnip
      cmp_luasnip
      friendly-snippets

      # --- ファジーファインダー ---
      plenary-nvim
      telescope-nvim
      nvim-surround

      # --- UI ---
      which-key-nvim
      lualine-nvim
      bufferline-nvim
      noice-nvim
      nui-nvim
      nvim-notify
      gitsigns-nvim
      comment-nvim
    ];

    extraLuaConfig = ''
      --------------------------------------------------------------------
      -- 0. 基本設定
      --------------------------------------------------------------------
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "

      local opt = vim.opt
      opt.number = true
      opt.relativenumber = true
      opt.cursorline = true
      opt.mouse = "a"
      opt.wrap = true
      opt.linebreak = true
      opt.ignorecase = true
      opt.smartcase = true
      opt.termguicolors = true
      opt.signcolumn = "yes"
      opt.scrolloff = 4
      opt.updatetime = 250
      opt.timeoutlen = 400
      opt.splitright = true
      opt.splitbelow = true
      opt.undofile = true
      opt.clipboard = "unnamedplus"
      opt.expandtab = true
      opt.shiftwidth = 2
      opt.tabstop = 2

      opt.guicursor = table.concat({
        "n-v-c:block",
        "i-ci-ve:ver25",
        "r-cr:hor20",
        "o:hor50",
      }, ",")

      --------------------------------------------------------------------
      -- 1. カラースキーム
      --------------------------------------------------------------------
      require("catppuccin").setup({ flavour = "mocha" })
      vim.cmd.colorscheme("catppuccin")

      --------------------------------------------------------------------
      -- 2. AniMotion.nvim (Helixの選択→操作モデル)
      --------------------------------------------------------------------
      require("AniMotion").setup({
        mode = "helix",
        edit_keys = { "c", "d", "s", "r", "y" },
        clear_keys = { "<Esc>" },
        map_visual = true,
        color = "Visual",
      })

      --------------------------------------------------------------------
      -- 3. Treesitter (mainブランチの新API。nvim-treesitter.configsは廃止)
      --------------------------------------------------------------------
      -- withAllGrammars で全パーサーがNix経由で事前インストール済みなので
      -- require("nvim-treesitter").install(...) は不要。
      -- ハイライト/インデント/折り畳みはFileTypeイベントで自前で有効化する。
      -- (注: 旧APIにあった incremental_selection は新APIには存在しない)
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          pcall(vim.treesitter.start)
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
          vim.wo[0][0].foldmethod = "expr"
        end,
      })

      require("nvim-treesitter-textobjects").setup({
        select = {
          lookahead = true,
          selection_modes = {
            ["@parameter.outer"] = "v",
            ["@function.outer"] = "V",
            ["@class.outer"] = "V",
          },
        },
        move = {
          set_jumps = true,
        },
      })

      do
        local ts_select = require("nvim-treesitter-textobjects.select")
        local function map_textobj(mode, key, query)
          vim.keymap.set(mode, key, function()
            ts_select.select_textobject(query, "textobjects")
          end)
        end

        map_textobj({ "x", "o" }, "af", "@function.outer")
        map_textobj({ "x", "o" }, "if", "@function.inner")
        map_textobj({ "x", "o" }, "ac", "@class.outer")
        map_textobj({ "x", "o" }, "ic", "@class.inner")
      end
      require("nvim-surround").setup({})

      --------------------------------------------------------------------
      -- 4. 補完 (nvim-cmp)
      --------------------------------------------------------------------
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then luasnip.jump(-1)
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }),
      })

      --------------------------------------------------------------------
      -- 5. LSP (mason.nvimは使わず、Nixでインストールしたサーバーを直接setup)
      --------------------------------------------------------------------
      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      lspconfig.lua_ls.setup({ capabilities = capabilities })
      -- extraPackages に言語サーバーを追加したら、ここにも setup を追記してください。例:
      -- lspconfig.nil_ls.setup({ capabilities = capabilities })
      -- lspconfig.pyright.setup({ capabilities = capabilities })
      -- lspconfig.rust_analyzer.setup({ capabilities = capabilities })

      --------------------------------------------------------------------
      -- 6. which-key (Helix風Spaceモードのポップアップ)
      --------------------------------------------------------------------
      require("which-key").setup({
        preset = "helix",
      })

      --------------------------------------------------------------------
      -- 7. バッファライン / コマンドライン UI
      --------------------------------------------------------------------
      require("bufferline").setup({
        options = {
          mode = "buffers",
          diagnostics = "nvim_lsp",
          show_buffer_close_icons = true,
          show_close_icon = false,
          separator_style = "slant",
          offsets = {
            { filetype = "NvimTree", text = "ファイル", separator = true },
          },
        },
      })

      require("notify").setup({ timeout = 2500 })
      require("noice").setup({
        cmdline = {
          enabled = true,
          view = "cmdline_popup",
        },
        messages = { enabled = true },
        popupmenu = { enabled = true },
        notify = { enabled = true },
        presets = {
          bottom_search = true,
          command_palette = true,
          long_message_to_split = true,
          inc_rename = false,
          lsp_doc_border = true,
        },
      })

      --------------------------------------------------------------------
      -- 8. ステータスライン
      --------------------------------------------------------------------
      require("lualine").setup({
        sections = {
          lualine_a = {
            function()
              if package.loaded["AniMotion"] and require("AniMotion").isActive() then
                return "SEL"
              end
              local mode_map = { n = "NOR", i = "INS", v = "VIS", V = "V-L", ["\22"] = "V-B", c = "CMD" }
              return mode_map[vim.fn.mode()] or vim.fn.mode()
            end,
          },
        },
      })

      --------------------------------------------------------------------
      -- 9. Git差分表示 / コメントアウト
      --------------------------------------------------------------------
      require("gitsigns").setup({})
      require("Comment").setup({})

      --------------------------------------------------------------------
      -- 10. マルチカーソル (multicursor.nvim)
      --------------------------------------------------------------------
      local mc = require("multicursor-nvim")
      mc.setup()

      do
        local set = vim.keymap.set

        set({ "n", "x" }, "<C-Down>", function() mc.lineAddCursor(1) end, { desc = "下の行にカーソル追加" })
        set({ "n", "x" }, "<C-Up>", function() mc.lineAddCursor(-1) end, { desc = "上の行にカーソル追加" })

        set({ "n", "x" }, "<leader>n", function() mc.matchAddCursor(1) end, { desc = "次の一致にカーソル追加" })
        set({ "n", "x" }, "<leader>N", function() mc.matchAddCursor(-1) end, { desc = "前の一致にカーソル追加" })
        set({ "n", "x" }, "<leader>s", function() mc.matchSkipCursor(1) end, { desc = "次の一致へスキップ" })
        set({ "n", "x" }, "<leader>A", mc.matchAllAddCursors, { desc = "全ての一致にカーソル追加" })
        set({ "n", "x" }, "ga", mc.addCursorOperator, { desc = "各行にカーソル追加" })

        set("n", "<c-leftmouse>", mc.handleMouse)
        set("n", "<c-leftdrag>", mc.handleMouseDrag)
        set("n", "<c-leftrelease>", mc.handleMouseRelease)
        set({ "n", "x" }, "<C-q>", mc.toggleCursor, { desc = "カーソルの有効/無効" })

        mc.addKeymapLayer(function(layerSet)
          layerSet({ "n", "x" }, "<Tab>", mc.nextCursor, { desc = "次のカーソルをメインに" })
          layerSet({ "n", "x" }, "<S-Tab>", mc.prevCursor, { desc = "前のカーソルをメインに" })
          layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor, { desc = "カーソルを削除" })
          layerSet("n", "<Esc>", function()
            if not mc.cursorsEnabled() then
              mc.enableCursors()
            else
              mc.clearCursors()
            end
          end, { desc = "カーソルをクリア" })
        end)

        local hl = vim.api.nvim_set_hl
        hl(0, "MultiCursorCursor", { reverse = true })
        hl(0, "MultiCursorVisual", { link = "Visual" })
        hl(0, "MultiCursorSign", { link = "SignColumn" })
        hl(0, "MultiCursorMatchPreview", { link = "Search" })
        hl(0, "MultiCursorDisabledCursor", { reverse = true })
        hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
        hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
      end

      --------------------------------------------------------------------
      -- 11. キーマップ (Helixのキー体系に寄せる)
      --------------------------------------------------------------------
      local map = vim.keymap.set

      -- Ctrl-c でコメントのトグル (Helixと同じキー)
      map("n", "<C-c>", function() require("Comment.api").toggle.linewise.current() end, { desc = "コメントトグル" })
      map("v", "<C-c>", "<Esc><Cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
        { desc = "コメントトグル(選択範囲)" })

      -- Space mode
      map("n", "<leader>f", function() require("telescope.builtin").find_files() end, { desc = "ファイルを開く" })
      map("n", "<leader>F", function() require("telescope.builtin").find_files({ hidden = true }) end, { desc = "隠しファイルも含めて開く" })
      map("n", "<leader>b", function() require("telescope.builtin").buffers() end, { desc = "バッファ一覧" })
      map("n", "<leader>e", "<Cmd>BufferLineCycleNext<CR>", { desc = "次のバッファ" })
      map("n", "<leader>E", "<Cmd>BufferLineCyclePrev<CR>", { desc = "前のバッファ" })
      map("n", "<leader>x", "<Cmd>BufferLinePickClose<CR>", { desc = "バッファを閉じる" })
      map("n", "<leader>/", function() require("telescope.builtin").live_grep() end, { desc = "プロジェクト内を検索 (grep)" })
      map("n", "<leader>j", function() require("telescope.builtin").jumplist() end, { desc = "ジャンプリスト" })
      map("n", "<leader>ls", function() require("telescope.builtin").lsp_document_symbols() end, { desc = "シンボル一覧(現ファイル)" })
      map("n", "<leader>lS", function() require("telescope.builtin").lsp_workspace_symbols() end, { desc = "シンボル一覧(プロジェクト全体)" })
      map("n", "<leader>a", vim.lsp.buf.code_action, { desc = "コードアクション" })
      map("n", "<leader>r", vim.lsp.buf.rename, { desc = "リネーム" })
      map("n", "<leader>d", vim.diagnostic.open_float, { desc = "診断メッセージを表示" })
      map("n", "<leader>D", vim.diagnostic.setloclist, { desc = "診断一覧" })
      map("n", "<leader>h", vim.lsp.buf.references, { desc = "シンボル参照" })
      map("n", "<leader>?", function() require("telescope.builtin").commands() end, { desc = "コマンドパレット" })
      map("n", "<leader>y", '"+y', { desc = "クリップボードへヤンク" })
      map("v", "<leader>y", '"+y', { desc = "選択範囲をクリップボードへヤンク" })
      map("n", "<leader>p", '"+p', { desc = "クリップボードを貼り付け" })
      map("n", "<leader>P", '"+P', { desc = "クリップボードを前に貼り付け" })

      -- Helix の Space+w ウィンドウモード
      map("n", "<leader>wv", "<Cmd>vsplit<CR>", { desc = "垂直分割" })
      map("n", "<leader>ws", "<Cmd>split<CR>", { desc = "水平分割" })
      map("n", "<leader>ww", "<C-w>w", { desc = "次のウィンドウ" })
      map("n", "<leader>wh", "<C-w>h", { desc = "左のウィンドウ" })
      map("n", "<leader>wj", "<C-w>j", { desc = "下のウィンドウ" })
      map("n", "<leader>wk", "<C-w>k", { desc = "上のウィンドウ" })
      map("n", "<leader>wl", "<C-w>l", { desc = "右のウィンドウ" })
      map("n", "<leader>wo", "<C-w>o", { desc = "他のウィンドウを閉じる" })
      map("n", "<leader>wq", "<C-w>q", { desc = "ウィンドウを閉じる" })

      -- Space+m: Helix のマーク操作に近い名前付きマーク
      map("n", "<leader>ma", function()
        local mark = vim.fn.input("マーク名: ")
        mark = mark:sub(1, 1)
        if mark:match("^[A-Za-z]$") then
          vim.api.nvim_buf_set_mark(0, mark, vim.fn.line("."), vim.fn.col(".") - 1, {})
        end
      end, { desc = "マークを追加" })
      map("n", "<leader>mr", function()
        local mark = vim.fn.input("削除するマーク: ")
        mark = mark:sub(1, 1)
        if mark:match("^[A-Za-z]$") then vim.api.nvim_del_mark(mark) end
      end, { desc = "マークを削除" })
      map("n", "<leader>ml", "<Cmd>marks<CR>", { desc = "マーク一覧" })

      -- g mode (goto)
      map("n", "gd", vim.lsp.buf.definition, { desc = "定義へ" })
      map("n", "gD", vim.lsp.buf.declaration, { desc = "宣言へ" })
      map("n", "gr", vim.lsp.buf.references, { desc = "参照一覧" })
      map("n", "gy", vim.lsp.buf.type_definition, { desc = "型定義へ" })
      map("n", "gi", vim.lsp.buf.implementation, { desc = "実装へ" })
      map("n", "K", vim.lsp.buf.hover, { desc = "ホバー情報" })

      -- Helix の変更・選択操作に寄せた基本キー
      map("n", "U", "<C-r>", { desc = "やり直し" })
      map("n", "x", "V", { desc = "行を選択" })
      map("v", ";", "<Esc>", { desc = "選択を解除" })
      map("v", ">", ">gv", { desc = "インデント" })
      map("v", "<", "<gv", { desc = "インデント解除" })

      -- ウィンドウ移動
      map("n", "<C-h>", "<C-w>h", { desc = "左のウィンドウへ" })
      map("n", "<C-j>", "<C-w>j", { desc = "下のウィンドウへ" })
      map("n", "<C-k>", "<C-w>k", { desc = "上のウィンドウへ" })
      map("n", "<C-l>", "<C-w>l", { desc = "右のウィンドウへ" })

      -- 保存 / 終了（Space+w は Helix のウィンドウモードに予約）
      map("n", "<leader>W", "<Cmd>w<CR>", { desc = "保存" })
      map("n", "<leader>q", "<Cmd>q<CR>", { desc = "終了" })

      -- lazygit (extraPackagesで供給したバイナリを組み込みターミナルで起動)
      map("n", "<leader>g", function()
        vim.cmd("botright 15split | terminal lazygit")
        vim.cmd("startinsert")
      end, { desc = "lazygitを開く" })

      --------------------------------------------------------------------
      -- 12. Helix公式キーマップ互換レイヤー
      -- https://docs.helix-editor.com/keymap.html
      --
      -- NeovimにはHelixの一時モードがないため、g/m/z/Spaceを
      -- プレフィックスとして同じキー列に割り当てる。
      --------------------------------------------------------------------
      local function ex(command)
        return "<Cmd>" .. command .. "<CR>"
      end

      -- Normal: movement / changes / selection
      map("n", "<C-b>", "<C-u>", { desc = "半ページ上へ" })
      map("n", "<C-f>", "<C-d>", { desc = "半ページ下へ" })
      map("n", "<C-u>", "<C-u>", { desc = "半ページ上へ" })
      map("n", "<C-d>", "<C-d>", { desc = "半ページ下へ" })
      map("n", "<C-i>", "<C-i>", { desc = "ジャンプ前進" })
      map("n", "<C-o>", "<C-o>", { desc = "ジャンプ後退" })
      map("n", "<C-s>", ex("normal! m'"), { desc = "選択をジャンプリストへ保存" })
      map("n", "G", "G", { desc = "指定行／ファイル末尾へ" })
      map("n", "H", "^", { desc = "行頭へ" })
      map("n", "L", "$", { desc = "行末へ" })
      map("n", "r", "r", { desc = "1文字置換" })
      map("n", "R", "R", { desc = "ヤンクで置換" })
      map("n", "~", "~", { desc = "大文字小文字切替" })
      map("n", "I", "I", { desc = "行頭で挿入" })
      map("n", "A", "A", { desc = "行末で挿入" })
      map("n", "o", "o", { desc = "下に行を開く" })
      map("n", "O", "O", { desc = "上に行を開く" })
      map("n", ".", ".", { desc = "直前の挿入を繰り返す" })
      map("n", "u", "u", { desc = "元に戻す" })
      map("n", "y", "y", { desc = "ヤンク" })
      map("n", "p", "p", { desc = "後ろへ貼り付け" })
      map("n", "P", "P", { desc = "前へ貼り付け" })
      map("n", "q", "@", { desc = "マクロを再生" })
      map("n", "Q", "q", { desc = "マクロを記録" })
      map("n", "<M-u>", ex("earlier 1f"), { desc = "履歴を戻る" })
      map("n", "<M-U>", ex("later 1f"), { desc = "履歴を進む" })
      map("n", ">", ">>", { desc = "インデント" })
      map("n", "<", "<<", { desc = "インデント解除" })
      map({ "n", "x" }, "=", function() vim.lsp.buf.format({ async = true }) end, { desc = "フォーマット" })
      map({ "n", "x" }, "d", "d", { desc = "選択を削除" })
      map({ "n", "x" }, "c", "c", { desc = "選択を変更" })
      map("n", "<C-a>", "<C-a>", { desc = "数値を増加" })
      map("n", "<C-x>", "<C-x>", { desc = "数値を減少" })

      -- 検索
      map("n", "/", "/", { desc = "検索" })
      map("n", "?", "?", { desc = "逆方向検索" })
      map("n", "n", "n", { desc = "次の検索結果" })
      map("n", "N", "N", { desc = "前の検索結果" })
      map("n", "*", "*", { desc = "カーソル下を検索" })

      -- Select / extend mode と selection manipulation
      map("n", "v", "v", { desc = "選択モード" })
      map("n", "%", "ggVG", { desc = "ファイル全体を選択" })
      map("x", "x", "V", { desc = "現在行を選択" })
      map("x", "X", "$o0", { desc = "行境界まで選択" })
      map("x", "<M-x>", "0o$", { desc = "行境界へ縮小" })
      map("x", "J", "J", { desc = "行を結合" })
      map("x", "C", "yyp", { desc = "下の行へコピー" })
      map("x", "<M-C>", "yyP", { desc = "上の行へコピー" })
      map("x", ";", "<Esc>", { desc = "選択をカーソルへ縮小" })
      map("x", ",", "<Esc>", { desc = "主選択だけ残す" })
      map("x", "<M-;>", "o", { desc = "選択方向を反転" })
      map("x", "<C-c>", function() require("Comment.api").toggle.linewise(vim.fn.visualmode()) end,
        { desc = "コメント切替" })
      map("x", "<M-o>", function() vim.cmd("normal! va") end, { desc = "親ノードを選択" })
      map("x", "<M-i>", function() vim.cmd("normal! vi") end, { desc = "内側ノードを選択" })

      -- Shell mappings (選択範囲を外部コマンドへ渡す)
      local function shell_range(append)
        vim.ui.input({ prompt = "shell: " }, function(command)
          if command and command ~= "" then
            vim.cmd("'<,'>!" .. command .. (append and " >/dev/null" or ""))
          end
        end)
      end
      map("x", "|", shell_range, { desc = "選択をshellで置換" })
      map("x", "<M-|>", function() shell_range(true) end, { desc = "選択をshellへ送る" })
      map("x", "!", shell_range, { desc = "shell出力を挿入" })

      -- g: Goto mode
      map("n", "gg", "gg", { desc = "ファイル先頭／指定行へ" })
      map("n", "g|", "0", { desc = "行頭／指定列へ" })
      map("n", "ge", "G", { desc = "ファイル末尾へ" })
      map("n", "gf", "gf", { desc = "ファイルへ移動" })
      map("n", "gh", "^", { desc = "行頭へ" })
      map("n", "gl", "$", { desc = "行末へ" })
      map("n", "gs", "^", { desc = "最初の非空白へ" })
      map("n", "gt", "H", { desc = "画面上端へ" })
      map("n", "gc", "M", { desc = "画面中央へ" })
      map("n", "gb", "L", { desc = "画面下端へ" })
      map("n", "gd", vim.lsp.buf.definition, { desc = "定義へ" })
      map("n", "gy", vim.lsp.buf.type_definition, { desc = "型定義へ" })
      map("n", "gr", vim.lsp.buf.references, { desc = "参照へ" })
      map("n", "gi", vim.lsp.buf.implementation, { desc = "実装へ" })
      map("n", "ga", "<C-^>", { desc = "直前のファイルへ" })
      map("n", "gm", ex("e#"), { desc = "直前に変更したファイルへ" })
      map("n", "gn", ex("bnext"), { desc = "次のバッファ" })
      map("n", "gp", ex("bprevious"), { desc = "前のバッファ" })
      map("n", "g.", "g;", { desc = "直前の変更位置へ" })
      map("n", "gj", "gj", { desc = "表示行ではなく論理行へ下" })
      map("n", "gk", "gk", { desc = "表示行ではなく論理行へ上" })

      -- z: View mode
      map("n", "zz", "zz", { desc = "カーソル行を中央" })
      map("n", "zc", "zz", { desc = "カーソル行を中央" })
      map("n", "zt", "zt", { desc = "カーソル行を上端" })
      map("n", "zb", "zb", { desc = "カーソル行を下端" })
      map("n", "zm", "zH", { desc = "水平中央" })
      map("n", "zj", "<C-e>", { desc = "表示を下へ" })
      map("n", "zk", "<C-y>", { desc = "表示を上へ" })
      map("n", "z<C-f>", "<C-f>", { desc = "1ページ下へ" })
      map("n", "z<C-b>", "<C-b>", { desc = "1ページ上へ" })
      map("n", "z<C-u>", "<C-u>", { desc = "半ページ上へ" })
      map("n", "z<C-d>", "<C-d>", { desc = "半ページ下へ" })

      -- m: Match mode / textobjects / surround
      map("n", "mm", "%", { desc = "対応する括弧へ" })
      map("n", "ms", "ys", { desc = "選択を囲む" })
      map("n", "mr", "cs", { desc = "囲みを置換" })
      map("n", "md", "ds", { desc = "囲みを削除" })
      map("n", "ma", "va", { desc = "textobjectをaround選択" })
      map("n", "mi", "vi", { desc = "textobjectをinside選択" })

      -- Space mode: 公式の全エントリ
      map("n", "<leader>g", function() require("telescope.builtin").git_status() end, { desc = "変更ファイル" })
      map("n", "<leader>G", function() require("telescope.builtin").git_commits() end, { desc = "Gitコミット" })
      map("n", "<leader>k", vim.lsp.buf.hover, { desc = "ホバー情報" })
      map("n", "<leader>s", function() require("telescope.builtin").lsp_document_symbols() end, { desc = "文書シンボル" })
      map("n", "<leader>S", function() require("telescope.builtin").lsp_workspace_symbols() end, { desc = "ワークスペースシンボル" })
      map("n", "<leader>h", vim.lsp.buf.references, { desc = "シンボル参照" })
      map("n", "<leader>'", function() require("telescope.builtin").resume() end, { desc = "最後のpicker" })
      map("n", "<leader>c", function() require("Comment.api").toggle.linewise.current() end, { desc = "コメント切替" })
      map("x", "<leader>c", function() require("Comment.api").toggle.linewise(vim.fn.visualmode()) end, { desc = "コメント切替" })
      map("n", "<leader>/", function() require("telescope.builtin").live_grep() end, { desc = "ワークスペース検索" })
      map("n", "<leader>?", function() require("telescope.builtin").commands() end, { desc = "コマンドパレット" })

      -- Unimpaired: diagnostics / changes / paragraphs
      map("n", "]d", vim.diagnostic.goto_next, { desc = "次の診断" })
      map("n", "[d", vim.diagnostic.goto_prev, { desc = "前の診断" })
      map("n", "]D", function() vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR }) end,
        { desc = "最後の診断" })
      map("n", "[D", function() vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR }) end,
        { desc = "最初の診断" })
      map("n", "]p", "}", { desc = "次の段落" })
      map("n", "[p", "{", { desc = "前の段落" })
      map("n", "]g", "]c", { desc = "次の変更" })
      map("n", "[g", "[c", { desc = "前の変更" })
      map("n", "]G", "G", { desc = "最後の変更" })
      map("n", "[G", "gg", { desc = "最初の変更" })
      map("n", "]<Space>", "o<Esc>", { desc = "下に空行追加" })
      map("n", "[<Space>", "O<Esc>", { desc = "上に空行追加" })

      -- Insert mode: Helixの公式insertキー
      map("i", "<C-s>", "<C-g>u", { desc = "undo checkpoint" })
      map("i", "<C-x>", "<C-Space>", { desc = "補完" })
      map("i", "<C-w>", "<C-w>", { desc = "前の単語を削除" })
      map("i", "<M-BS>", "<C-w>", { desc = "前の単語を削除" })
      map("i", "<M-d>", "<C-o>dw", { desc = "次の単語を削除" })
      map("i", "<C-u>", "<C-u>", { desc = "行頭まで削除" })
      map("i", "<C-k>", "<C-o>D", { desc = "行末まで削除" })
      map("i", "<C-h>", "<BS>", { desc = "前の文字を削除" })
      map("i", "<C-d>", "<Del>", { desc = "次の文字を削除" })
      map("i", "<C-j>", "<CR>", { desc = "改行" })

      -- ターミナルバッファ内でEscでノーマルモードに戻れるようにする
      vim.api.nvim_create_autocmd("TermOpen", {
        callback = function()
          vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { buffer = true })
        end,
      })
    '';
  };
}
