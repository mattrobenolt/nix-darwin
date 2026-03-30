{ inputs, pkgs, ... }:
{
  imports = [
    inputs.nixvim.homeModules.nixvim
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # Plugins
    extraPlugins = with pkgs.vimPlugins; [
      dracula-nvim
    ];

    plugins = {
      # Status line
      lualine = {
        enable = true;
        settings = {
          options = {
            theme = "dracula-nvim";
            globalstatus = false;
          };
          sections = {
            lualine_x = [
              "encoding"
              "filetype"
            ];
          };
        };
      };

      # Auto pairs
      nvim-autopairs = {
        enable = true;
        settings = {
          check_ts = true;
        };
      };

      # Commenting
      comment = {
        enable = true;
      };

      # Git signs
      gitsigns = {
        enable = true;
      };

      # Snippets
      luasnip = {
        enable = true;
      };

      # Treesitter
      treesitter = {
        enable = true;
        settings = {
          indent.enable = true;
          highlight = {
            enable = true;
            additional_vim_regex_highlighting = false;
            disable = ''
              function(lang, buf)
                local max_filesize = 20 * 1024 * 1024 -- 20 MB
                local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
                if ok and stats and stats.size > max_filesize then
                  return true
                end
              end
            '';
          };
        };
        grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          bash
          c
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
          html
          javascript
          jq
          json
          json5
          jsonnet
          lua
          make
          markdown
          markdown_inline
          proto
          python
          rst
          ruby
          rust
          ssh_config
          toml
          typescript
          vim
          yaml
          zig
        ];
      };

      # LSP kind icons
      lspkind = {
        enable = true;
        settings = {
          cmp = {
            enable = true;
            menu = {
              buffer = "[Buffer]";
              nvim_lsp = "[LSP]";
              nvim_lua = "[Lua]";
            };
          };
        };
      };

      # LSP
      lsp = {
        enable = true;

        keymaps = {
          diagnostic = {
            "<leader>e" = "open_float";
          };
          lspBuf = {
            "gD" = "declaration";
            "gd" = "definition";
            "K" = "hover";
            "gi" = "implementation";
            "<C-k>" = "signature_help";
            "<leader>wa" = "add_workspace_folder";
            "<leader>wr" = "remove_workspace_folder";
            "<leader>D" = "type_definition";
            "<leader>rn" = "rename";
            "<leader>ca" = "code_action";
            "gr" = "references";
            "<leader>f" = "format";
          };
        };

        servers = {
          ty = {
            enable = true;
            cmd = [
              "${pkgs.uv}/bin/uvx"
              "ty@latest"
              "server"
            ];
          };

          # Python - ruff for linting/formatting
          ruff = {
            enable = true;
            extraOptions = {
              init_options = {
                settings = {
                  lint = {
                    extendSelect = [ "I" ]; # Import sorting
                  };
                };
              };
            };
          };

          # Go - from devshell
          gopls = {
            enable = true;
            extraOptions = {
              settings = {
                gopls = {
                  usePlaceholders = true;
                  gofumpt = true;
                  analyses = {
                    nilness = true;
                    unusedparams = true;
                    unusedwrite = true;
                    useany = true;
                    stdmethods = false; # Disabled in Zed
                    ST1000 = false; # Disabled in Zed
                    ST1013 = false; # Disabled in Zed
                  };
                  codelenses = {
                    gc_details = true;
                    generate = true;
                    test = true;
                    tidy = true;
                    upgrade_dependency = true;
                    vendor = false; # Disabled in Zed
                  };
                  completeUnimported = true;
                  staticcheck = true;
                  semanticTokens = true;
                  hints = {
                    assignVariableTypes = true;
                    compositeLiteralFields = true;
                    compositeLiteralTypes = true;
                    constantValues = true;
                    functionTypeParameters = true;
                    parameterNames = true;
                    rangeVariableTypes = true;
                  };
                  buildFlags = [
                    "-tags"
                    "goexperiment.jsonv2,goexperiment.synctest"
                  ];
                  templateExtensions = [
                    "html"
                    "tmpl"
                    "tpl"
                  ];
                };
              };
            };
          };

          # Zig - from devshell
          zls = {
            enable = true;
            extraOptions = {
              init_options = {
                enable_build_on_save = true;
              };
            };
          };

          # Rust - from devshell
          rust_analyzer = {
            enable = true;
            installCargo = false;
            installRustc = false;
            settings = {
              inlayHints = {
                maxLength = null;
                lifetimeElisionHints = {
                  enable = "skip_trivial";
                  useParameterNames = true;
                };
                closureReturnTypeHints = {
                  enable = "always";
                };
              };
            };
          };

          # Nix
          nixd = {
            enable = true;
            settings = {
              formatting = {
                command = [ "nixfmt" ];
              };
            };
          };
        };
      };

      # Completion
      cmp = {
        enable = true;
        settings = {
          snippet.expand = "function(args) require('luasnip').lsp_expand(args.body) end";

          mapping = {
            "<C-n>" = "cmp.mapping.select_next_item()";
            "<C-p>" = "cmp.mapping.select_prev_item()";
            "<C-b>" = "cmp.mapping.scroll_docs(-4)";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-e>" = "cmp.mapping.abort()";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<Tab>" = {
              __raw = ''
                cmp.mapping(function(fallback)
                  local luasnip = require('luasnip')
                  if cmp.visible() then
                    cmp.select_next_item()
                  elseif luasnip.expand_or_locally_jumpable() then
                    luasnip.expand_or_jump()
                  else
                    fallback()
                  end
                end, {"i", "s"})
              '';
            };
          };

          sources = [
            { name = "nvim_lsp"; }
            {
              name = "luasnip";
              keywordLength = 2;
            }
            {
              name = "buffer";
              keywordLength = 5;
            }
          ];

          preselect = "cmp.PreselectMode.None";
        };
      };
    };

    extraConfigLua = ''
      -- Setup dracula with transparent background
      local dracula = require("dracula")
      dracula.setup({
        transparent_bg = true,
        italic_comment = true,
        show_end_of_buffer = true,
      })
      vim.cmd.colorscheme("dracula")
    '';

    # Global settings
    globals = {
      mapleader = " ";
      maplocalleader = "\\";
      # Disable netrw
      loaded_netrw = 1;
      loaded_netrwPlugin = 1;
    };

    # Options (from your options.lua)
    opts = {
      # Indentation
      autoindent = true;
      expandtab = true;
      shiftwidth = 4;
      tabstop = 4;

      # Search
      hlsearch = true;
      ignorecase = true;
      incsearch = true;
      smartcase = true;

      # UI
      number = true;
      relativenumber = true;
      signcolumn = "yes";
      termguicolors = true;
      colorcolumn = "+1";
      showmode = false;
      title = true;
      pumblend = 10;

      # Behavior
      autowrite = true;
      clipboard = "unnamedplus";
      mouse = "a";
      mousemoveevent = true;
      smoothscroll = true;
      undofile = true;
      undolevels = 10000;

      # Splits
      splitbelow = true;
      splitright = true;

      # Text
      encoding = "utf-8";
      fileformat = "unix";
      textwidth = 100;
      wrap = true;

      # Whitespace
      list = true;
      listchars = "tab:> ,trail:-,space:·";

      # Grep
      grepformat = "%f:%l:%c:%m";
      grepprg = "rg --vimgrep";
    };

    # Autocmds (basic ones, skipping LSP-related for now)
    autoGroups = {
      matt_checktime = {
        clear = true;
      };
      matt_tiny_indent = {
        clear = true;
      };
      matt_go_indent = {
        clear = true;
      };
      matt_resize_splits = {
        clear = true;
      };
    };

    autoCmd = [
      # Auto-reload files when they change
      {
        event = [
          "FocusGained"
          "TermClose"
          "TermLeave"
        ];
        group = "matt_checktime";
        callback = {
          __raw = ''
            function()
              if vim.o.buftype ~= "nofile" then
                vim.cmd("checktime")
              end
            end
          '';
        };
      }

      # 2-space indent for certain languages
      {
        event = "FileType";
        group = "matt_tiny_indent";
        pattern = [
          "lua"
          "javascript"
          "hcl"
          "json"
          "yaml"
          "typescript"
        ];
        command = "setlocal tabstop=2 shiftwidth=2";
      }

      # Go uses tabs
      {
        event = "FileType";
        group = "matt_go_indent";
        pattern = [ "go" ];
        command = "setlocal noexpandtab";
      }

      # Resize splits on window resize
      {
        event = "VimResized";
        group = "matt_resize_splits";
        callback = {
          __raw = ''
            function()
              local current_tab = vim.fn.tabpagenr()
              vim.cmd("tabdo wincmd =")
              vim.cmd("tabnext " .. current_tab)
            end
          '';
        };
      }

      # Format Go on save
      {
        event = "BufWritePre";
        group = "matt_go_fmt_on_save";
        pattern = [ "*.go" ];
        callback = {
          __raw = ''
            function()
              vim.lsp.buf.code_action({
                context = {
                  only = { "source.organizeImports" },
                },
                apply = true,
              })
              vim.lsp.buf.format({ async = false })
            end
          '';
        };
      }

      # Format Python on save
      {
        event = "BufWritePre";
        group = "matt_py_fmt_on_save";
        pattern = [ "*.py" ];
        callback = {
          __raw = ''
            function()
              vim.lsp.buf.code_action({
                context = {
                  only = { "source.organizeImports.ruff" }
                },
                apply = true,
              })
              vim.lsp.buf.format({ async = false })
            end
          '';
        };
      }
    ];
  };
}
