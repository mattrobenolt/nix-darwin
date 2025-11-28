return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,
        enable_git_status = true,
        window = {
          position = "right",
        },
        follow_current_file = {
          enabled = true,
        },
        source_selector = {
          winbar = true,
          sources = {
            { source = "filesystem" },
            { source = "document_symbols" },
          },
        },
        sources = {
          "filesystem",
          "document_symbols",
        },
      })
    end,
  },
}
