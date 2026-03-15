-- Bootstrap lazy.nvim
-- local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
-- if not (vim.uv or vim.loop).fs_stat(lazypath) then
--   local lazyrepo = "https://github.com/folke/lazy.nvim.git"
--   local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
--   if vim.v.shell_error ~= 0 then
--     vim.api.nvim_echo({
--       { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
--       { out, "WarningMsg" },
--       { "\nPress any key to exit..." },
--     }, true, {})
--     vim.fn.getchar()
--     os.exit(1)
--   end
-- end
-- vim.opt.rtp:prepend(lazypath)
--
-- require("lazy").setup({
return {
  "rebelot/kanagawa.nvim",
  {
    "ellisonleao/gruvbox.nvim",
    config = function()
      vim.cmd.colorscheme("gruvbox")
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "c", 
          "lua", 
          "vim", 
          "vimdoc", 
          "query", 
          "markdown", 
          "markdown_inline", 
          "html", 
          "latex", 
          "yaml", 
          "python", 
          "arduino", 
          "json",
        },

        auto_install = true,

        highlight = {
          enable = true,
        },
      })
    end,
  },
  {
    "zk-org/zk-nvim",
    config = function()
      require("zk").setup({
        -- Can be "telescope", "fzf", "fzf_lua", "minipick", "snacks_picker",
        -- or select" (`vim.ui.select`).
        picker = "snacks_picker",

        lsp = {
          -- `config` is passed to `vim.lsp.start(config)`
          config = {
            name = "zk",
            cmd = { "zk", "lsp" },
            filetypes = { "markdown" },
            cmd_env = {
              ZK_NOTEBOOK_DIR = vim.fn.expand("~/notes"),
            },
            -- on_attach = ...
            -- etc, see `:h vim.lsp.start()`
          },

          -- automatically attach buffers in a zk notebook that match the given filetypes
          auto_attach = {
            enabled = true,
          },
        },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- require("zklsp")
    end,
  },
  {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
      image = {
        -- your image configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
      },
      picker = {
        -- your picker configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
      },
    },
  },
  {
    "OXY2DEV/markview.nvim",
    lazy = false,
    ft = { "markdown", "md" },

    -- For `nvim-treesitter` users.
    priority = 49,

    -- For blink.cmp"s completion
    -- source
    -- dependencies = {
      --     "saghen/blink.cmp"
      -- },
    },
    {
      "folke/which-key.nvim",
      event = "VeryLazy",
      opts = {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
      },
      keys = {
        {
          "<leader>?",
          function()
            require("which-key").show({ global = false })
          end,
          desc = "Buffer Local Keymaps (which-key)",
        },
      },
    },
    {
      "saghen/blink.cmp",
      dependencies = { "rafamadriz/friendly-snippets" },

      version = "1.*",
      opts = {
        -- "default" (recommended) for mappings similar to built-in completions (C-y to accept)
        -- "super-tab" for mappings similar to vscode (tab to accept)
        -- "enter" for enter to accept
        -- "none" for no mappings
        --
        -- All presets have the following mappings:
        -- C-space: Open menu or open docs if already open
        -- C-n/C-p or Up/Down: Select next/previous item
        -- C-e: Hide menu
        -- C-k: Toggle signature help (if signature.enabled = true)
        --
        -- See :h blink-cmp-config-keymap for defining your own keymap
        keymap = { preset = "super-tab" },

        appearance = {
          nerd_font_variant = "mono"
        },

        completion = { documentation = { auto_show = true } },

        sources = {
          default = { "lsp", "path", "snippets", "buffer" },
          -- org = {'orgmode'}
        },
        -- providers = {
        --   orgmode = {
        --     name = 'Orgmode',
        --     module = 'orgmode.org.autocompletion.blink',
        --     fallbacks = { 'buffer' },
        --   },
        -- },

        fuzzy = { implementation = "prefer_rust_with_warning" }
      },
      opts_extend = { "sources.default" }
    }
  }

