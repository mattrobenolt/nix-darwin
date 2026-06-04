{ inputs, pkgs, ... }:
{
  imports = [ inputs.nixvim.homeModules.nixvim ];

  programs.nixvim = {
    enable = true;
    nixpkgs.source = pkgs.path;
    package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    extraPlugins = with pkgs.vimPlugins; [
      dracula-nvim
      lualine-nvim
      nvim-web-devicons
      gitsigns-nvim
      nvim-autopairs
      fff-nvim
    ];

    extraConfigLua = ''
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          local max_filesize = 20 * 1024 * 1024
          local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(args.buf))
          if ok and stats and stats.size > max_filesize then
            vim.treesitter.stop(args.buf)
          end
        end,
      })

      vim.filetype.add({
        extension = {
          gotmpl = 'gotmpl',
          tmpl = function(path, _)
            local dir = vim.fs.dirname(path)
            if vim.fs.find({ 'go.mod', 'go.work' }, { path = dir, upward = true })[1] then
              return 'gotmpl'
            end
            return 'template'
          end,
        },
      })

      -- LSP keymaps on attach
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local opts = { noremap = true, silent = true, buffer = args.buf }
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
          vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
          vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
          vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, opts)
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
          vim.keymap.set('n', '<space>f', function()
            vim.lsp.buf.format({ async = true })
          end, opts)

          vim.lsp.completion.enable(true, args.data.client_id, args.buf, {
            autotrigger = true,
          })
        end,
      })

      vim.opt.completeopt = { 'menu', 'menuone', 'noselect', 'popup' }

      vim.diagnostic.config({
        float = { border = "rounded" },
      })

      vim.lsp.config('gopls', {
        cmd = { 'gopls' },
        filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
        root_markers = { 'go.work', 'go.mod', '.git' },
        settings = {
          gopls = {
            usePlaceholders = true,
            gofumpt = true,
            analyses = {
              stdmethods = false,
              ST1000 = false,
              ST1013 = false,
            },
            codelenses = {
              gc_details = true,
              generate = true,
              test = true,
              tidy = true,
              upgrade_dependency = true,
              vendor = false,
            },
            completeUnimported = true,
            staticcheck = true,
            semanticTokens = true,
            buildFlags = { '-tags', 'goexperiment.jsonv2,goexperiment.synctest' },
            templateExtensions = { 'html', 'tmpl', 'tpl' },
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              compositeLiteralTypes = true,
              constantValues = true,
              functionTypeParameters = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
          },
        },
      })
      vim.lsp.enable('gopls')

      vim.lsp.config('ruff', {
        cmd = { 'ruff', 'server' },
        filetypes = { 'python' },
        root_markers = { 'pyproject.toml', 'ruff.toml', 'setup.cfg', 'setup.py', '.git' },
        settings = {
          lint = { extendSelect = { 'I' } },
        },
        on_attach = function(client)
          client.server_capabilities.hoverProvider = false
        end,
      })
      vim.lsp.enable('ruff')

      vim.lsp.config('ty', {
        cmd = { 'ty', 'server' },
        filetypes = { 'python' },
        root_markers = { 'pyproject.toml', '.git' },
      })
      vim.lsp.enable('ty')

      vim.lsp.config('nixd', {
        cmd = { 'nixd' },
        filetypes = { 'nix' },
        root_markers = { 'flake.nix', '.git' },
        settings = {
          nixd = {
            formatting = { command = { 'nixfmt' } },
          },
        },
      })
      vim.lsp.enable('nixd')

      vim.lsp.config('zls', {
        cmd = { 'zls' },
        filetypes = { 'zig', 'zir' },
        root_markers = { 'zls.json', 'build.zig', '.git' },
        settings = {
          zls = { enable_build_on_save = true },
        },
      })
      vim.lsp.enable('zls')

      vim.lsp.config('rust_analyzer', {
        cmd = { 'rust-analyzer' },
        filetypes = { 'rust' },
        root_markers = { 'Cargo.toml', 'Cargo.lock', '.git' },
        settings = {
          ['rust-analyzer'] = {
            inlayHints = {
              maxLength = nil,
              lifetimeElisionHints = {
                enable = 'skip_trivial',
                useParameterNames = true,
              },
              closureReturnTypeHints = { enable = 'always' },
            },
          },
        },
      })
      vim.lsp.enable('rust_analyzer')

      vim.lsp.config('yamlls', {
        cmd = { 'yaml-language-server', '--stdio' },
        filetypes = { 'yaml' },
        root_markers = { '.git' },
        settings = {
          yaml = {
            format = { singleQuote = true },
          },
        },
      })
      vim.lsp.enable('yamlls')

      vim.lsp.config('ruby_lsp', {
        cmd = { 'ruby-lsp' },
        filetypes = { 'ruby' },
        root_markers = { 'Gemfile', '.git' },
        init_options = {
          enabledFeatures = { diagnostics = false },
        },
      })
      vim.lsp.enable('ruby_lsp')

      require('fff').setup({ prompt_position = 'top' })
      vim.keymap.set('n', '<C-p>', function() require('fff').find_files() end, { desc = 'Find files' })
      vim.keymap.set('n', '<C-/>', function() require('fff').live_grep() end, { desc = 'Live grep' })

      require("dracula").setup({
        show_end_of_buffer = true,
        transparent_bg = true,
        italic_comment = true,
      })
      vim.cmd.colorscheme("dracula")

      require("gitsigns").setup()
      require("nvim-autopairs").setup({ check_ts = true })

      require("lualine").setup({
        options = {
          theme = "dracula-nvim",
          globalstatus = false,
        },
        sections = {
          lualine_x = { "encoding", "filetype" },
        },
      })
    '';

    plugins.treesitter = {
      enable = true;
      highlight.enable = true;
      settings = {
        indent.enable = true;
        highlight.additional_vim_regex_highlighting = false;
      };
      grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        bash
        c
        css
        csv
        diff
        dockerfile
        git_config
        git_rebase
        gitattributes
        gitcommit
        gitignore
        go
        gomod
        gosum
        gotmpl
        gowork
        hcl
        hjson
        html
        htmldjango
        ini
        javascript
        jq
        json
        json5
        jsonnet
        just
        lua
        make
        markdown
        markdown_inline
        nix
        nu
        proto
        python
        rst
        ruby
        rust
        ssh_config
        terraform
        toml
        typescript
        vim
        vimdoc
        yaml
        zig
        zsh
      ];
    };

    globals = {
      mapleader = " ";
      maplocalleader = "\\";
      loaded_netrw = 1;
      loaded_netrwPlugin = 1;
    };

    opts = {
      autoindent = true;
      autowrite = true;
      backspace = "2";
      clipboard = "unnamedplus";
      encoding = "utf-8";
      expandtab = true;
      fileformat = "unix";
      grepformat = "%f:%l:%c:%m";
      grepprg = "rg --vimgrep";
      hlsearch = true;
      ignorecase = true;
      incsearch = true;
      list = true;
      listchars = "tab:> ,trail:-,space:·";
      mouse = "a";
      mousemoveevent = true;
      colorcolumn = "+1";
      number = true;
      pumblend = 10;
      relativenumber = true;
      shiftwidth = 4;
      showmode = false;
      signcolumn = "yes";
      smartcase = true;
      smoothscroll = true;
      splitbelow = true;
      splitright = true;
      tabstop = 4;
      termguicolors = true;
      textwidth = 100;
      title = true;
      undofile = true;
      undolevels = 10000;
      wrap = true;
    };

    autoGroups = {
      checktime.clear = true;
      tiny_indent.clear = true;
      go_indent.clear = true;
      go_fmt_on_save.clear = true;
      py_fmt_on_save.clear = true;
      resize_splits.clear = true;
    };

    autoCmd = [
      {
        event = [
          "FocusGained"
          "TermClose"
          "TermLeave"
        ];
        group = "checktime";
        callback.__raw = ''
          function()
            if vim.o.buftype ~= "nofile" then
              vim.cmd("checktime")
            end
          end
        '';
      }
      {
        event = "FileType";
        group = "tiny_indent";
        pattern = [
          "lua"
          "javascript"
          "hcl"
          "json"
          "nix"
          "yaml"
          "typescript"
        ];
        command = "setlocal tabstop=2 shiftwidth=2";
      }
      {
        event = "FileType";
        group = "go_indent";
        pattern = [ "go" ];
        command = "setlocal noexpandtab";
      }
      {
        event = "BufWritePre";
        group = "go_fmt_on_save";
        pattern = [ "*.go" ];
        callback.__raw = ''
          function()
            vim.lsp.buf.code_action({
              context = { only = { "source.organizeImports" } },
              apply = true,
            })
            vim.lsp.buf.format({ async = false })
          end
        '';
      }
      {
        event = "BufWritePre";
        group = "py_fmt_on_save";
        pattern = [ "*.py" ];
        callback.__raw = ''
          function()
            vim.lsp.buf.code_action({
              context = { only = { "source.organizeImports.ruff" } },
              apply = true,
            })
            vim.lsp.buf.format({ async = false })
          end
        '';
      }
      {
        event = [ "VimResized" ];
        group = "resize_splits";
        callback.__raw = ''
          function()
            local current_tab = vim.fn.tabpagenr()
            vim.cmd("tabdo wincmd =")
            vim.cmd("tabnext " .. current_tab)
          end
        '';
      }
    ];
  };
}
