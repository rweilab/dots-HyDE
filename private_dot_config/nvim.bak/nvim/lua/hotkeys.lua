vim.g.mapleader = (" ")

vim.keymap.set("n", "<Leader>fnn", function()
  Snacks.picker.files({cwd = "~/notes"})
end, {desc = "Find notes by name"})

vim.keymap.set("n", "<Leader>fng", function()
  Snacks.picker.grep({cwd = "~/notes"})
end, {desc = "Grep notes"})

vim.keymap.set("n", "<Leader>zn", function()
  local title = vim.fn.input("Note title: ")
  require("zk").new({
    title = title,
    dir = vim.fn.expand("~/notes/+"),
  })
end, {desc = "Create a NAMED note"})


vim.keymap.set("n", "<Leader>zh", function()
  vim.lsp.buf.hover()
end, {desc = "Hover with LSP"})

vim.keymap.set("n", "gd", function()
  vim.lsp.buf.definition()
end, {desc = "Jump to definition!"})

-- -- simple buffer-local remap for org files: <leader>ox toggles checkbox
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "org",
--   callback = function()
--     local opts = { buffer = true, noremap = true, silent = true, desc = "Org: toggle checkbox" }
--
--     -- remove plugin's possibly-present <C-Space> buffer mapping to avoid confusion
--     pcall(vim.api.nvim_buf_del_keymap, 0, "n", "<C-Space>")
--     pcall(vim.api.nvim_buf_del_keymap, 0, "v", "<C-Space>")
--
--     -- map <leader>ox to the same plugin action, using a command string (robust)
--     vim.keymap.set("n", "<leader>o ",
--       "<Cmd>lua require('orgmode').action('org_mappings.toggle_checkbox')<CR>",
--       opts)
--   end,
-- })
