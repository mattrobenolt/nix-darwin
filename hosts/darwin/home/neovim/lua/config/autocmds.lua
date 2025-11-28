local function augroup(name)
  return vim.api.nvim_create_augroup("matt_" .. name, { clear = true })
end

-- Check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("tiny_indent"),
  pattern = {
    "lua",
    "javascript",
    "hcl",
    "json",
    "yaml",
    "typescript",
  },
  command = "setlocal tabstop=2 shiftwidth=2",
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("go_indent"),
  pattern = { "go" },
  command = "setlocal noexpandtab",
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("go_fmt_on_save"),
  pattern = { "*.go" },
  callback = function()
    vim.lsp.buf.code_action({
      context = {
        only = { "source.organizeImports" },
      },
      apply = true,
    })
    vim.lsp.buf.format({async = false})
  end
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("py_fmt_on_save"),
  pattern = { "*.py" },
  callback = function()
    vim.lsp.buf.code_action({
      context = {
        only = { "source.organizeImports.ruff" }
      },
      apply = true,
    })
    vim.lsp.buf.format({async = false})
  end
})

-- resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})
