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
      sha256 = lib.fakeHash; # ← ビルド時のエラーメッセージに従って置き換える
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

      # --- UI ---
      which-key-nvim
      lualine-nvim
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
      -- 7. ステータスライン
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
      -- 8. Git差分表示 / コメントアウト
      --------------------------------------------------------------------
      require("gitsigns").setup({})
      require("Comment").setup({})

      --------------------------------------------------------------------
      -- 9. マルチカーソル (multicursor.nvim)
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
      -- 10. キーマップ (Helixのキー体系に寄せる)
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
      map("n", "<leader>/", function() require("telescope.builtin").live_grep() end, { desc = "プロジェクト内を検索 (grep)" })
      map("n", "<leader>j", function() require("telescope.builtin").jumplist() end, { desc = "ジャンプリスト" })
      map("n", "<leader>ls", function() require("telescope.builtin").lsp_document_symbols() end, { desc = "シンボル一覧(現ファイル)" })
      map("n", "<leader>lS", function() require("telescope.builtin").lsp_workspace_symbols() end, { desc = "シンボル一覧(プロジェクト全体)" })
      map("n", "<leader>a", vim.lsp.buf.code_action, { desc = "コードアクション" })
      map("n", "<leader>r", vim.lsp.buf.rename, { desc = "リネーム" })
      map("n", "<leader>d", vim.diagnostic.open_float, { desc = "診断メッセージを表示" })

      -- g mode (goto)
      map("n", "gd", vim.lsp.buf.definition, { desc = "定義へ" })
      map("n", "gr", vim.lsp.buf.references, { desc = "参照一覧" })
      map("n", "gy", vim.lsp.buf.type_definition, { desc = "型定義へ" })
      map("n", "gi", vim.lsp.buf.implementation, { desc = "実装へ" })
      map("n", "K", vim.lsp.buf.hover, { desc = "ホバー情報" })

      -- ウィンドウ移動
      map("n", "<C-h>", "<C-w>h", { desc = "左のウィンドウへ" })
      map("n", "<C-j>", "<C-w>j", { desc = "下のウィンドウへ" })
      map("n", "<C-k>", "<C-w>k", { desc = "上のウィンドウへ" })
      map("n", "<C-l>", "<C-w>l", { desc = "右のウィンドウへ" })

      -- 保存 / 終了
      map("n", "<leader>w", "<Cmd>w<CR>", { desc = "保存" })
      map("n", "<leader>q", "<Cmd>q<CR>", { desc = "終了" })

      -- lazygit (extraPackagesで供給したバイナリを組み込みターミナルで起動)
      map("n", "<leader>g", function()
        vim.cmd("botright 15split | terminal lazygit")
        vim.cmd("startinsert")
      end, { desc = "lazygitを開く" })

      -- ターミナルバッファ内でEscでノーマルモードに戻れるようにする
      vim.api.nvim_create_autocmd("TermOpen", {
        callback = function()
          vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { buffer = true })
        end,
      })
    '';
  };
}
