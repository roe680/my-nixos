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
      cmp-cmdline
      cmp-path
      cmp-nvim-lsp
      luasnip
      cmp_luasnip
      friendly-snippets

      # --- ファジーファインダー ---
      plenary-nvim
      telescope-nvim
      nvim-surround
      flash-nvim

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
      require("flash").setup({})

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
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<Down>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<Up>"] = cmp.mapping.select_prev_item(),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }),
      })

      -- Helixの `:` コマンド／パス補完。通常のInsert補完とは別設定が必要。
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline({
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<Down>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<Up>"] = cmp.mapping.select_prev_item(),
          ["<C-u>"] = cmp.mapping.scroll_docs(-4),
          ["<C-d>"] = cmp.mapping.scroll_docs(4),
          ["<C-r>"] = function()
            local register = vim.fn.getcharstr()
            if register ~= "" then
              vim.fn.feedkeys(vim.fn.getreg(register:sub(1, 1)), "n")
            end
          end,
          ["<C-s>"] = function()
            local word = vim.fn.expand("<cword>")
            vim.fn.feedkeys(word, "n")
          end,
        }),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
      })
      cmp.setup.cmdline("/", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
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

      -- Helix の hover popup と同じく、popup にフォーカスしてスクロールできるようにする。
      vim.lsp.handlers.hover = function(err, result, ctx, config)
        if err or not result or not result.contents then return end
        local markdown = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
        markdown = vim.lsp.util.trim_empty_lines(markdown)
        if vim.tbl_isempty(markdown) then return end
        local bufnr, winid = vim.lsp.util.open_floating_preview(markdown, "markdown", {
          border = "rounded",
          focus = true,
          focus_id = "helix-hover",
          max_width = math.floor(vim.o.columns * 0.7),
          max_height = math.floor(vim.o.lines * 0.4),
        })
        vim.keymap.set("n", "<C-u>", function()
          vim.api.nvim_win_call(winid, function()
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-u>", true, false, true), "n", false)
          end)
        end, { buffer = bufnr, silent = true, desc = "hoverを上へスクロール" })
        vim.keymap.set("n", "<C-d>", function()
          vim.api.nvim_win_call(winid, function()
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-d>", true, false, true), "n", false)
          end)
        end, { buffer = bufnr, silent = true, desc = "hoverを下へスクロール" })
        vim.keymap.set("n", "q", function()
          if vim.api.nvim_win_is_valid(winid) then vim.api.nvim_win_close(winid, true) end
        end, { buffer = bufnr, silent = true, desc = "hoverを閉じる" })
        vim.keymap.set("n", "<Esc>", function()
          if vim.api.nvim_win_is_valid(winid) then vim.api.nvim_win_close(winid, true) end
        end, { buffer = bufnr, silent = true, desc = "hoverを閉じる" })
      end

      -- Signature-help は候補一覧を保持し、Alt-p/Alt-n で overload を切り替える。
      local signature_state = { signatures = {}, index = 1, winid = nil }
      local function render_signature()
        if vim.api.nvim_win_is_valid(signature_state.winid or -1) then
          vim.api.nvim_win_close(signature_state.winid, true)
        end
        local signature = signature_state.signatures[signature_state.index]
        if not signature then return end
        local lines = { signature.label }
        if signature.documentation then
          local docs = signature.documentation
          if type(docs) == "table" then docs = docs.value end
          if docs and docs ~= "" then
            vim.list_extend(lines, vim.split(docs, "\n", { plain = true }))
          end
        end
        local _, winid = vim.lsp.util.open_floating_preview(lines, "markdown", {
          border = "rounded",
          focus = false,
          focus_id = "helix-signature",
        })
        signature_state.winid = winid
      end
      vim.lsp.handlers["textDocument/signatureHelp"] = function(err, result)
        if err or not result or not result.signatures or #result.signatures == 0 then return end
        signature_state.signatures = result.signatures
        signature_state.index = math.min((result.activeSignature or 0) + 1, #result.signatures)
        render_signature()
      end
      local function cycle_signature(delta)
        if #signature_state.signatures == 0 then
          vim.lsp.buf.signature_help()
          return
        end
        signature_state.index = ((signature_state.index - 1 + delta) % #signature_state.signatures) + 1
        render_signature()
      end

      --------------------------------------------------------------------
      -- 6. which-key (Helix風Spaceモードのポップアップ)
      --------------------------------------------------------------------
      require("which-key").setup({
        preset = "helix",
      })
      require("which-key").add({
        { "<leader>", group = "Space" },
        { "<leader>w", group = "Window" },
        { "<leader>m", group = "Multicursor" },
        { "<leader>f", desc = "ファイルを開く" },
        { "<leader>F", desc = "隠しファイルを開く" },
        { "<leader>b", desc = "バッファ一覧" },
        { "<leader>s", desc = "文書シンボル" },
        { "<leader>S", desc = "ワークスペースシンボル" },
        { "<leader>k", desc = "ホバー情報" },
        { "<leader>d", desc = "診断メッセージ" },
        { "<leader>D", desc = "ワークスペース診断" },
        { "<leader>a", desc = "コードアクション" },
        { "<leader>r", desc = "リネーム" },
        { "<leader>h", desc = "参照" },
        { "<leader>c", desc = "行コメント" },
        { "<leader>C", desc = "ブロックコメント" },
        { "<leader>?", desc = "コマンドパレット" },
        { "<leader>ms", desc = "次の一致をスキップ" },
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

      require("telescope").setup({
        defaults = {
          mappings = {
            i = {
              ["<C-s>"] = require("telescope.actions").select_horizontal,
              ["<C-v>"] = require("telescope.actions").select_vertical,
              ["<C-t>"] = require("telescope.actions").toggle_preview,
              ["<C-n>"] = require("telescope.actions").move_selection_next,
              ["<C-p>"] = require("telescope.actions").move_selection_previous,
              ["<Down>"] = require("telescope.actions").move_selection_next,
              ["<Up>"] = require("telescope.actions").move_selection_previous,
              ["<C-u>"] = require("telescope.actions").preview_scrolling_up,
              ["<C-d>"] = require("telescope.actions").preview_scrolling_down,
              ["<Home>"] = require("telescope.actions").move_to_top,
              ["<End>"] = require("telescope.actions").move_to_bottom,
              ["<M-CR>"] = require("telescope.actions").select_tab,
            },
            n = {
              ["<C-s>"] = require("telescope.actions").select_horizontal,
              ["<C-v>"] = require("telescope.actions").select_vertical,
              ["<C-t>"] = require("telescope.actions").toggle_preview,
              ["<C-u>"] = require("telescope.actions").preview_scrolling_up,
              ["<C-d>"] = require("telescope.actions").preview_scrolling_down,
              ["<Home>"] = require("telescope.actions").move_to_top,
              ["<End>"] = require("telescope.actions").move_to_bottom,
              ["<M-CR>"] = require("telescope.actions").select_tab,
            },
          },
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
        set({ "n", "x" }, "<leader>ms", function() mc.matchSkipCursor(1) end, { desc = "次の一致へスキップ" })
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

      -- Helixでよく使う短いコマンドをNeovimでも使えるようにする。
      local function format_buffer()
        vim.lsp.buf.format({ async = true })
      end
      vim.api.nvim_create_user_command("Fmt", format_buffer, { desc = "現在のバッファをフォーマット" })
      vim.api.nvim_create_user_command("Format", format_buffer, { desc = "現在のバッファをフォーマット" })
      vim.api.nvim_create_user_command("W", "write", { desc = "保存" })
      vim.api.nvim_create_user_command("Wq", "wq", { desc = "保存して終了" })
      vim.api.nvim_create_user_command("Q", "quit", { desc = "終了" })
      vim.api.nvim_create_user_command("Bd", "bdelete", { desc = "バッファを閉じる" })
      vim.api.nvim_create_user_command("Bn", "bnext", { desc = "次のバッファ" })
      vim.api.nvim_create_user_command("Bp", "bprevious", { desc = "前のバッファ" })

      -- Ctrl-c でコメントのトグル (Helixと同じキー)
      map("n", "<C-c>", function() require("Comment.api").toggle.linewise.current() end, { desc = "コメントトグル" })
      map("v", "<C-c>", "<Esc><Cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
        { desc = "コメントトグル(選択範囲)" })

      -- Helixのf/F/t/Tは行境界を越えるため、flash.nvimでラベル検索にする。
      local function flash_motion(forward, pos)
        require("flash").jump({
          search = { mode = "search", forward = forward, wrap = true },
          jump = { pos = pos or "start" },
          label = { after = { 0, 0 } },
        })
      end
      map({ "n", "x", "o" }, "f", function() flash_motion(true, "start") end, { desc = "ラベル付き文字検索" })
      map({ "n", "x", "o" }, "F", function() flash_motion(false, "start") end, { desc = "ラベル付き逆文字検索" })
      map({ "n", "x", "o" }, "t", function() flash_motion(true, "end") end, { desc = "ラベル付き文字手前検索" })
      map({ "n", "x", "o" }, "T", function() flash_motion(false, "end") end, { desc = "ラベル付き逆文字手前検索" })

      -- Space mode
      map("n", "<leader>f", function() require("telescope.builtin").find_files() end, { desc = "ファイルを開く" })
      map("n", "<leader>F", function() require("telescope.builtin").find_files({ hidden = true }) end, { desc = "隠しファイルも含めて開く" })
      map("n", "<leader>o", function()
        require("telescope.builtin").find_files({ cwd = vim.fn.expand("%:p:h") })
      end, { desc = "現在のファイルのディレクトリから開く" })
      map("n", "<leader>b", function() require("telescope.builtin").buffers() end, { desc = "バッファ一覧" })
      map("n", "<leader>e", "<Cmd>BufferLineCycleNext<CR>", { desc = "次のバッファ" })
      map("n", "<leader>E", "<Cmd>BufferLineCyclePrev<CR>", { desc = "前のバッファ" })
      map("n", "<leader>x", "<Cmd>BufferLinePickClose<CR>", { desc = "バッファを閉じる" })
      map("n", "<leader>j", function() require("telescope.builtin").jumplist() end, { desc = "ジャンプリスト" })
      map("n", "<leader>ls", function() require("telescope.builtin").lsp_document_symbols() end, { desc = "シンボル一覧(現ファイル)" })
      map("n", "<leader>lS", function() require("telescope.builtin").lsp_workspace_symbols() end, { desc = "シンボル一覧(プロジェクト全体)" })
      map("n", "<leader>a", vim.lsp.buf.code_action, { desc = "コードアクション" })
      map("n", "<leader>r", vim.lsp.buf.rename, { desc = "リネーム" })
      map("n", "<leader>d", vim.diagnostic.open_float, { desc = "診断メッセージを表示" })
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
      map("n", "x", function()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("V", true, false, true), "n", false)
      end, { desc = "行を選択", nowait = true })
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

      -- 提示された Helix 設定の normal キーを同じキー列で再現
      map("n", "<A-w>", "<Cmd>bdelete<CR>", { desc = "バッファを閉じる" })
      map("n", "<Tab>", "<Cmd>bnext<CR>", { desc = "次のバッファ" })
      map("n", "<S-Tab>", "<Cmd>bprevious<CR>", { desc = "前のバッファ" })
      map("n", "<C-k>", "ddkP", { desc = "行を上へ移動" })
      map("n", "<C-j>", "ddp", { desc = "行を下へ移動" })
      map("n", "<A-x>", "V$", { desc = "行境界まで選択を拡張" })
      map("n", "X", "Vk", { desc = "上の行まで選択" })
      map("n", "+w", function()
        vim.opt.list = not vim.opt.list:get()
      end, { desc = "空白文字表示を切替" })
      map("n", "+s", function()
        vim.opt.wrap = not vim.opt.wrap:get()
      end, { desc = "ソフトラップを切替" })
      map("n", "+f", format_buffer, { desc = "フォーマット" })
      map("x", "H", "^", { desc = "選択を行頭へ" })
      map("x", "L", "$", { desc = "選択を行末へ" })
      map("i", "jk", "<Esc>", { desc = "ノーマルモードへ" })

      -- lazygit (extraPackagesで供給したバイナリを組み込みターミナルで起動)
      map("n", "<leader>l", function()
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
      map("n", "<C-b>", "<C-b>", { desc = "1ページ上へ" })
      map("n", "<C-f>", "<C-f>", { desc = "1ページ下へ" })
      map("n", "<C-u>", "<C-u>", { desc = "半ページ上へ" })
      map("n", "<C-d>", "<C-d>", { desc = "半ページ下へ" })
      map("n", "<C-i>", "<C-i>", { desc = "ジャンプ前進" })
      map("n", "<C-o>", "<C-o>", { desc = "ジャンプ後退" })
      map("n", "<C-s>", ex("normal! m'"), { desc = "選択をジャンプリストへ保存" })
      map("n", "<M-.>", function() flash_motion(true, "start") end, { desc = "直前のモーションをラベル検索" })
      map("n", "G", "G", { desc = "指定行／ファイル末尾へ" })
      map("n", "H", "^", { desc = "行頭へ" })
      map("n", "L", "$", { desc = "行末へ" })
      map("n", "r", "r", { desc = "1文字置換" })
      map("n", "R", "R", { desc = "ヤンクで置換" })
      map("n", "~", "~", { desc = "大文字小文字切替" })
      map("x", "`", "gu", { desc = "小文字化" })
      map("x", "<M-`>", "gU", { desc = "大文字化" })
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
      map({ "n", "x" }, "<M-d>", '"_d', { desc = "ヤンクせず削除" })
      map({ "n", "x" }, "<M-c>", '"_c', { desc = "ヤンクせず変更" })
      map("n", "<C-a>", "<C-a>", { desc = "数値を増加" })
      map("n", "<C-x>", "<C-x>", { desc = "数値を減少" })

      -- 検索
      map("n", "/", "/", { desc = "検索" })
      map("n", "?", "?", { desc = "逆方向検索" })
      map("n", "n", "n", { desc = "次の検索結果" })
      map("n", "N", "N", { desc = "前の検索結果" })
      map("n", "*", "*", { desc = "カーソル下を検索" })
      map("n", "<M-*>", function()
        vim.fn.setreg("/", vim.fn.escape(vim.fn.getreg('"'), "\\"))
        vim.cmd("normal! n")
      end, { desc = "選択を検索語にする" })
      map("x", "<M-*>", function()
        local start_row, start_col = vim.fn.getpos("'<")[2], vim.fn.getpos("'<")[3]
        local end_row, end_col = vim.fn.getpos("'>")[2], vim.fn.getpos("'>")[3]
        local lines = vim.api.nvim_buf_get_text(0, start_row - 1, start_col - 1, end_row - 1, end_col, {})
        local text = table.concat(lines, "\n")
        if text ~= "" then
          vim.fn.setreg("/", vim.fn.escape(text, "\\"))
          vim.cmd("normal! n")
        end
      end, { desc = "選択を単語境界なしで検索" })
      map("n", '"', function()
        local register = vim.fn.getcharstr()
        register = register:sub(1, 1)
        if register:match("^[0-9A-Za-z+*]$") then
          vim.g.helix_register = register
          vim.notify("register: " .. register)
        end
      end, { desc = "レジスタを選択" })
      local function use_helix_register(action)
        local register = vim.g.helix_register
        if not register then
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(action, true, false, true), "n", false)
          return
        end
        vim.g.helix_register = nil
        vim.api.nvim_feedkeys(
          vim.api.nvim_replace_termcodes('"' .. register .. action, true, false, true),
          "n",
          false
        )
      end
      for _, action in ipairs({ "y", "d", "c", "p", "P" }) do
        map({ "n", "x" }, action, function() use_helix_register(action) end,
          { desc = "選択レジスタを使って " .. action })
      end

      -- Select / extend mode と selection manipulation
      map("n", "v", "v", { desc = "選択モード" })
      map("n", "%", "ggVG", { desc = "ファイル全体を選択" })
      local function visual_line_range()
        local anchor = vim.fn.getpos("v")[2]
        local cursor = vim.fn.line(".")
        return math.min(anchor, cursor), math.max(anchor, cursor)
      end
      local function select_line_range(first, last, first_col, last_col)
        vim.fn.setpos("'<", { 0, first, first_col or 1, 0 })
        vim.fn.setpos("'>", { 0, last, last_col or #vim.fn.getline(last), 0 })
        vim.api.nvim_win_set_cursor(0, { last, math.max((last_col or #vim.fn.getline(last)) - 1, 0) })
        vim.cmd("normal! gv")
      end
      map("x", "x", function()
        local first, last = visual_line_range()
        select_line_range(first, math.min(last + 1, vim.api.nvim_buf_line_count(0)))
      end, { desc = "下の行まで選択を拡張" })
      map("x", "X", function()
        local first, last = visual_line_range()
        select_line_range(first, last, 1, #vim.fn.getline(last))
      end, { desc = "行境界まで選択" })
      map("x", "<M-x>", function()
        local first, last = visual_line_range()
        select_line_range(first, last, 1, #vim.fn.getline(last))
      end, { desc = "行境界へ縮小" })
      map("x", "J", "J", { desc = "行を結合" })
      map("x", "C", "yyp", { desc = "下の行へコピー" })
      map("x", "<M-C>", "yyP", { desc = "上の行へコピー" })
      map("x", ";", "<Esc>", { desc = "選択をカーソルへ縮小" })
      map("x", "<M-,>", function()
        require("multicursor-nvim").deleteCursor()
      end, { desc = "主選択以外を削除" })
      map("x", ",", "<Esc>", { desc = "主選択だけ残す" })
      map("x", "<M-;>", "o", { desc = "選択方向を反転" })
      map("x", "<M-:>", function()
        local start_row = vim.fn.line("'<")
        local end_row = vim.fn.line("'>")
        if start_row > end_row then vim.cmd("normal! o") end
      end, { desc = "選択方向を正規化" })
      map("x", "s", function() require("multicursor-nvim").matchCursors() end,
        { desc = "正規表現一致を選択" })
      map("x", "S", function() require("multicursor-nvim").splitCursors() end,
        { desc = "正規表現で選択を分割" })
      map("x", "<M-s>", function() require("multicursor-nvim").splitCursors() end,
        { desc = "選択を分割" })
      map("x", "<M-->", "J", { desc = "選択を結合" })
      map("x", "<M-_>", "J", { desc = "連続選択を結合" })
      map("x", "&", function() require("multicursor-nvim").alignCursors() end, { desc = "選択を整列" })
      map("x", "_", function()
        local first, last = visual_line_range()
        local lines = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
        for i, line in ipairs(lines) do lines[i] = line:gsub("%s+$", "") end
        vim.api.nvim_buf_set_lines(0, first - 1, last, false, lines)
      end, { desc = "末尾空白を削除" })
      map("x", "<M-(>", function() require("multicursor-nvim").transposeCursors(-1) end,
        { desc = "選択内容を逆回転" })
      map("x", "<M-)>", function() require("multicursor-nvim").transposeCursors(1) end,
        { desc = "選択内容を回転" })
      map("x", "(", "o", { desc = "選択方向を逆回転" })
      map("x", ")", "o", { desc = "選択方向を回転" })
      map("x", "<M-J>", function()
        local row = vim.fn.line(".")
        vim.cmd("normal! J")
        vim.api.nvim_win_set_cursor(0, { row, vim.fn.col(".") - 1 })
        vim.cmd("normal! v")
        vim.cmd("normal! l")
      end, { desc = "結合して空白を選択" })
      local function filter_visual_lines(keep)
        local pattern = vim.fn.input("regex: ")
        if pattern == "" then return end
        local first, last = visual_line_range()
        local matched = {}
        for line = first, last do
          local ok = vim.fn.match(vim.fn.getline(line), pattern) >= 0
          if ok == keep then table.insert(matched, line) end
        end
        if #matched == 0 then vim.cmd("normal! gv"); return end
        select_line_range(matched[1], matched[#matched], 1, #vim.fn.getline(matched[#matched]))
      end
      map("x", "K", function() filter_visual_lines(true) end, { desc = "一致選択を残す" })
      map("x", "<M-K>", function() filter_visual_lines(false) end, { desc = "一致選択を除外" })
      map("x", "<C-c>", function() require("Comment.api").toggle.linewise(vim.fn.visualmode()) end,
        { desc = "コメント切替" })
      map("x", "<M-o>", function() vim.cmd("normal! va") end, { desc = "親ノードを選択" })
      map("x", "<M-i>", function() vim.cmd("normal! vi") end, { desc = "内側ノードを選択" })
      map("x", "<M-p>", "<Esc><M-p>", { desc = "前の構文兄弟" })
      map("x", "<M-n>", "<Esc><M-n>", { desc = "次の構文兄弟" })
      local function select_tree_nodes(nodes)
        if #nodes == 0 then return end
        local first_row, first_col = math.huge, math.huge
        local last_row, last_col = -1, -1
        for _, node in ipairs(nodes) do
          local sr, sc, er, ec = node:range()
          if sr < first_row or (sr == first_row and sc < first_col) then
            first_row, first_col = sr, sc
          end
          if er > last_row or (er == last_row and ec > last_col) then
            last_row, last_col = er, ec
          end
        end
        vim.fn.setpos("'<", { 0, first_row + 1, first_col + 1, 0 })
        vim.fn.setpos("'>", { 0, last_row + 1, math.max(last_col, 1), 0 })
        vim.api.nvim_win_set_cursor(0, { last_row + 1, math.max(last_col - 1, 0) })
        vim.cmd("normal! gv")
      end
      local function select_tree_group(kind)
        local node = vim.treesitter.get_node({ bufnr = 0 })
        if not node then return end
        local parent = kind == "siblings" and node:parent() or node
        if not parent then return end
        local nodes = parent:named_children()
        select_tree_nodes(nodes)
      end
      map("x", "<M-a>", function() select_tree_group("siblings") end, { desc = "全ての兄弟ノードを選択" })
      map("x", "<M-I>", function() select_tree_group("children") end, { desc = "全ての子ノードを選択" })
      local function select_parent_edge(edge)
        local node = vim.treesitter.get_node({ bufnr = 0 })
        local parent = node and node:parent()
        if not parent then return end
        local sr, sc, er, ec = parent:range()
        if edge == "start" then
          vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
        else
          vim.api.nvim_win_set_cursor(0, { er, math.max(ec - 1, 0) })
        end
      end
      map("x", "<M-e>", function() select_parent_edge("end") end, { desc = "親ノード末尾" })
      map("x", "<M-b>", function() select_parent_edge("start") end, { desc = "親ノード先頭" })

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
      map("x", "<M-!>", function() shell_range(true) end, { desc = "shell出力を後置" })
      map("x", "$", function()
        vim.ui.input({ prompt = "shell (成功した選択を残す): " }, function(command)
          if command and command ~= "" then
            local text = table.concat(vim.fn.getline("'<", "'>"), "\n")
            local result = vim.system({ "sh", "-c", command }, { stdin = text }):wait()
            if result.code ~= 0 then vim.cmd("normal! gv") end
          end
        end)
      end, { desc = "成功した選択を残す" })

      -- g: Goto mode
      map("n", "gg", "gg", { desc = "ファイル先頭／指定行へ" })
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
      map("n", "gw", function() require("flash").jump() end, { desc = "単語ラベルでジャンプ" })
      map("n", "g|", function()
        local column = tonumber(vim.fn.input("column: "))
        if column then vim.api.nvim_win_set_cursor(0, { vim.fn.line("."), math.max(column - 1, 0) }) end
      end, { desc = "指定列へ" })

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
      local function select_textobject(around)
        local object = vim.fn.getcharstr()
        if object == "" then return end
        vim.cmd("normal! v" .. (around and "a" or "i") .. object)
      end
      map("n", "ma", function() select_textobject(true) end, { desc = "textobjectをaround選択" })
      map("n", "mi", function() select_textobject(false) end, { desc = "textobjectをinside選択" })
      map("n", "<C-w>H", "<C-w>H", { desc = "ウィンドウを左へ交換" })
      map("n", "<C-w>J", "<C-w>J", { desc = "ウィンドウを下へ交換" })
      map("n", "<C-w>K", "<C-w>K", { desc = "ウィンドウを上へ交換" })
      map("n", "<C-w>L", "<C-w>L", { desc = "ウィンドウを右へ交換" })
      map("n", "<C-w>f", function()
        local actions = require("telescope.actions")
        require("telescope.builtin").find_files({ attach_mappings = function(prompt_bufnr, map_picker)
          map_picker("i", "<CR>", function()
            actions.select_horizontal(prompt_bufnr)
          end)
          map_picker("n", "<CR>", function()
            actions.select_horizontal(prompt_bufnr)
          end)
          return true
        end })
      end, { desc = "ファイルを水平分割で開く" })
      map("n", "<C-w>F", function()
        local actions = require("telescope.actions")
        require("telescope.builtin").find_files({ attach_mappings = function(prompt_bufnr, map_picker)
          map_picker("i", "<CR>", function()
            actions.select_vertical(prompt_bufnr)
          end)
          map_picker("n", "<CR>", function()
            actions.select_vertical(prompt_bufnr)
          end)
          return true
        end })
      end, { desc = "ファイルを垂直分割で開く" })

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
      map("n", "<leader>C", function() require("Comment.api").toggle.blockwise.current() end, { desc = "ブロックコメント" })
      map("x", "<leader>C", function() require("Comment.api").toggle.blockwise(vim.fn.visualmode()) end,
        { desc = "ブロックコメント" })
      map("n", "<leader><M-c>", function() require("Comment.api").toggle.linewise.current() end,
        { desc = "行コメント" })
      map("n", "<leader>Y", '"+yy', { desc = "主行をクリップボードへヤンク" })
      map("x", "<leader>R", '"+p', { desc = "クリップボードで置換" })
      map("n", "<leader>D", vim.diagnostic.setqflist, { desc = "ワークスペース診断" })

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
      do
        local move = require("nvim-treesitter-textobjects.move")
        local function ts_diag(key, query, next_item)
          map("n", key, function()
            local fn = next_item and move.goto_next_start or move.goto_previous_start
            local ok = pcall(fn, query, "textobjects")
            if not ok and query == "@test.outer" then
              pcall(fn, "@function.outer", "textobjects")
            end
          end, { desc = "Tree-sitter対象へ移動" })
        end
        ts_diag("]f", "@function.outer", true)
        ts_diag("[f", "@function.outer", false)
        ts_diag("]t", "@class.outer", true)
        ts_diag("[t", "@class.outer", false)
        ts_diag("]T", "@test.outer", true)
        ts_diag("[T", "@test.outer", false)
        ts_diag("]a", "@parameter.outer", true)
        ts_diag("[a", "@parameter.outer", false)
        ts_diag("]c", "@comment.outer", true)
        ts_diag("[c", "@comment.outer", false)
      end

      -- Tree-sitter textobject の兄弟移動
      do
        local move = require("nvim-treesitter-textobjects.move")
        local function ts_move(key, query, direction)
          map("n", key, function()
            local fn = direction == "next" and move.goto_next_start or move.goto_previous_start
            fn(query, "textobjects")
          end, { desc = "Tree-sitter兄弟へ移動" })
        end
        ts_move("<M-n>", "@parameter.outer", "next")
        ts_move("<M-p>", "@parameter.outer", "prev")
        ts_move("<M-Right>", "@parameter.outer", "next")
        ts_move("<M-Left>", "@parameter.outer", "prev")
      end

      -- Insert mode: Helixの公式insertキー
      map("i", "<C-s>", "<C-g>u", { desc = "undo checkpoint" })
      map("i", "<C-x>", "<C-Space>", { desc = "補完" })
      map("i", "<C-r>", function()
        local register = vim.fn.getcharstr()
        if register ~= "" then
          vim.api.nvim_put({ vim.fn.getreg(register:sub(1, 1)) }, "c", true, true)
        end
      end, { desc = "レジスタを挿入" })
      map("i", "<C-w>", "<C-w>", { desc = "前の単語を削除" })
      map("i", "<M-BS>", "<C-w>", { desc = "前の単語を削除" })
      map("i", "<M-d>", "<C-o>dw", { desc = "次の単語を削除" })
      map("i", "<C-u>", "<C-u>", { desc = "行頭まで削除" })
      map("i", "<C-k>", "<C-o>D", { desc = "行末まで削除" })
      map("i", "<C-h>", "<BS>", { desc = "前の文字を削除" })
      map("i", "<C-d>", "<Del>", { desc = "次の文字を削除" })
      map("i", "<C-j>", "<CR>", { desc = "改行" })
      map("i", "<M-p>", function() cycle_signature(-1) end, { desc = "前のシグネチャ" })
      map("i", "<M-n>", function() cycle_signature(1) end, { desc = "次のシグネチャ" })
      map("c", "<C-r>", function()
        local register = vim.fn.getcharstr()
        if register ~= "" then vim.fn.feedkeys(vim.fn.getreg(register:sub(1, 1)), "n") end
      end, { desc = "レジスタを挿入" })
      map("c", "<C-s>", function()
        vim.fn.feedkeys(vim.fn.expand("<cword>"), "n")
      end, { desc = "カーソル下の単語を挿入" })
      map("c", "<M-b>", "<C-Left>", { desc = "前の単語へ" })
      map("c", "<M-f>", "<C-Right>", { desc = "次の単語へ" })

      -- ターミナルバッファ内でEscでノーマルモードに戻れるようにする
      vim.api.nvim_create_autocmd("TermOpen", {
        callback = function()
          vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { buffer = true })
        end,
      })
    '';
  };
}
