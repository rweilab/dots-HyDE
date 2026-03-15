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

-- Enable hybrid line numbers
vim.opt.number = true
vim.opt.relativenumber = false

-- Set up leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- Setup lazy.nvim and plugins
require("lazy").setup({
  spec = {
    {
      "rebelot/kanagawa.nvim",
      config = function()
        vim.cmd.colorscheme("kanagawa")
      end,
    },

    -- treesitter: ensure it's present before neorg
    {
      "nvim-treesitter/nvim-treesitter",
      lazy = false,
      build = ":TSUpdate",
      opts = {
        ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "norg", "python", "markdown" },
        highlight = { enable = true },
      },
      config = function(_, opts)
        require("nvim-treesitter.configs").setup(opts)
      end,
    },

    -- Neorg (no patches)
    {
      "nvim-neorg/neorg",
      lazy = false,
      version = "*",
      dependencies = { "nvim-treesitter/nvim-treesitter" },
      config = function()
        require("neorg").setup {
          load = {
            ["core.defaults"] = {},
            ["core.concealer"] = {
              config = { icon_preset = "diamond" },
            },
            ["core.dirman"] = {
              config = {
                workspaces = { notes = "~/notes" },
                default_workspace = "notes",
              },
            },
            -- no extra monkeypatches or integration patches here
          },
        }

        vim.wo.foldlevel = 99
        vim.wo.conceallevel = 2
      end,
    },

    {
      "windwp/nvim-autopairs",
      event = "InsertEnter",
      config = true,
    },

    {
      "kylechui/nvim-surround",
      version = "^3.0.0",
      event = "VeryLazy",
      config = function()
        require("nvim-surround").setup({})
      end,
    },
  },
})

