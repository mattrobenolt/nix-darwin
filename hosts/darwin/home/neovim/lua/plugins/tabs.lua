return {
  {
    "akinsho/bufferline.nvim", version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("bufferline").setup({
        options = {
          diagnostics = "nvim_lsp",
          always_show_bufferline = false,
          numbers = "ordinal",
          show_buffer_icons = true,
          separator_style = "thin",
          indicator = {
              icon = '▎', -- this should be omitted if indicator style is not 'icon'
              style = "icon",
          },
          hover = {
            enabled = true,
            delay = 50,
            reveal = {'close'},
          },
          offsets = {
            {
              filetype = "neo-tree",
              text = "",
              highlight = "Directory",
              text_align = "left"
            }
          },
        }
      })
    end
  },
}
