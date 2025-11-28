return {
  {
    "Mofiqul/dracula.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      local dracula = require("dracula")
      dracula.setup({
        show_end_of_buffer = true,
        transparent_bg = true,
        italic_comment = true,
      })
      vim.cmd.colorscheme "dracula"
    end,
  },

  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      local theme = require("catppuccin")
      theme.setup({
        show_end_of_buffer = true,
        transparent_background = false,
      })
    end,
  },
  {
    "nyoom-engineering/oxocarbon.nvim",
    name = "oxocarbon",
    lazy = false,
    priority = 1000,
    config = function()
      --vim.opt.background = "dark"
      --vim.cmd.colorscheme "oxocarbon"
      --vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
      --vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    end
  },

  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "dracula-nvim",
          globalstatus = false,
        },
        sections = {
          lualine_x = {'encoding', 'filetype'},
        },
      })
    end,
  },
}
