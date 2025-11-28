return {
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects"
    },
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "bash",
          "c",
          "diff",
          "dockerfile",
          "git_config",
          "git_rebase",
          "gitattributes",
          "gitcommit",
          "gitignore",
          "go",
          "gomod",
          "gosum",
          "gotmpl",
          "gowork",
          "hcl",
          "html",
          "javascript",
          "jq",
          "json",
          "json5",
          "jsonnet",
          "lua",
          "make",
          "markdown",
          "markdown_inline",
          "proto",
          "python",
          "rst",
          "ruby",
          "rust",
          "ssh_config",
          "toml",
          "typescript",
          "vim",
          "yaml",
          "zig",
        },
        indent = { enable = true },
        autopairs = { enable = true },
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,

          disable = function(lang, buf)
            local max_filesize = 20 * 1024 * 1024 -- 20 MB
            local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
              return true
            end
          end,
        },
      })
    end,
  },
}
