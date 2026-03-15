-- Set zk.nvim's note directory environment variable here:
vim.env.ZK_NOTEBOOK_DIR = vim.fn.expand("~/notes")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("options")

-- require("plugins")

-- require("org")


require("lazy").setup(
  vim.list_extend(
    require("org"),
    require("plugins")
  )
)
-- require("zklsp")

require("hotkeys")

--
require("my.zk_move_ui").setup({ notes_dir = "~/notes", keymap = "<leader>zm" })

-- force cleanup of org visuals from markdown
local function cleanup_markdown(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local ok_h, headlines = pcall(require, "headlines")
  if ok_h and headlines.namespace then
    pcall(vim.api.nvim_buf_clear_namespace, bufnr, headlines.namespace, 0, -1)
  end

  local ok_ob, orgbul = pcall(require, "org-bullets")
  if ok_ob and type(orgbul.detach) == "function" then
    pcall(orgbul.detach, bufnr)
  end

  local ok_mv, mv = pcall(require, "markview")
  if ok_mv and type(mv.attach) == "function" then
    pcall(mv.detach, bufnr)
    pcall(mv.attach, bufnr)
    if type(mv.render) == "function" then pcall(mv.render, bufnr) end
  end

  local winid = vim.fn.bufwinid(bufnr)
  if winid ~= -1 then
    pcall(vim.api.nvim_win_call, winid, function()
      vim.wo.conceallevel = 2
      vim.wo.concealcursor = "nc"
    end)
  end
end

-- run cleanup whenever we enter a markdown buffer
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
  pattern = { "*.md", "*.markdown", "*.mdx" },
  callback = function(args)
    -- delay to run *after* headlines/org autocommands
    vim.schedule(function()
      if vim.bo[args.buf].filetype == "markdown" then
        cleanup_markdown(args.buf)
      end
    end)
  end,
})

