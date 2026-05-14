vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.wrap = false

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2

vim.opt.scrolloff = 4

-- Synchronizes system clipboard with nvim"s keyboard
vim.opt.clipboard = "unnamedplus"

vim.opt.virtualedit = "block"

-- Creates a window to preview filewide substitutions
vim.opt.inccommand = "split"

vim.opt.ignorecase = true

-- Enables 24 bit color in the TUI
vim.opt.termguicolors = true

vim.g.mapleader = " "

-- Set up LSP diagnostic display
vim.diagnostic.config({
  virtual_text = false,
  virtual_lines = true,
})

vim.keymap.set("n", "<M-h>", "<C-w>h")
vim.keymap.set("n", "<M-j>", "<C-w>j")
vim.keymap.set("n", "<M-k>", "<C-w>k")
vim.keymap.set("n", "<M-l>", "<C-w>l")

-- Bootstrap Lazy
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

require("lazy").setup({
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("gruvbox")
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
      })
      require("nvim-treesitter").install({
        "lua", "vim", "bash", "typescript", "rust", "c", "cpp",
        "markdown", "markdown_inline", "latex", "html", "yaml", -- for render-markdown.nvim
      })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    event = {"BufReadPre", "BufNewFile"},
  },

 {
    "mason-org/mason.nvim",
    opts = {}
  },

  -- Set up mason.nvim and have nvim-lspconfig available in :h runtimepath before setting up mason-lspconfig.nvim.
  {
    "mason-org/mason-lspconfig.nvim",
    event = "BufReadPre",
    dependencies = {"mason-org/mason.nvim", "neovim/nvim-lspconfig"},
    config = function()
      require("mason-lspconfig").setup({
        automatic_enable = true
      })
      -- Note: This will only enable servers that are installed via Mason. It will not recognize servers installed elsewhere on your system.
    end,
  },

  {
    "saghen/blink.cmp",
    dependencies = { "rafamadriz/friendly-snippets" },
    version = "1.*",
    event = {"InsertEnter"},
    opts = {
      keymap = { preset = "super-tab" },
      appearance = { nerd_font_variant = "mono" },
      completion = { documentation = { auto_show = true } },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },
        },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" }
    },
    opts_extend = { "sources.default" }
  },

  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
  },

  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },

  {
    'nvim-mini/mini.clue',
    version = false,
    config = function()


      local miniclue = require('mini.clue')
      miniclue.setup({
        triggers = {
          { mode = 'n', keys = '<Leader>' },
          { mode = 'x', keys = '<Leader>' },

          -- Built-in completion
          { mode = 'i', keys = '<C-x>' },

          { mode = 'n', keys = 'g' },
          { mode = 'x', keys = 'g' },

          -- Marks
          { mode = 'n', keys = "'" },
          { mode = 'n', keys = '`' },
          { mode = 'x', keys = "'" },
          { mode = 'x', keys = '`' },

          -- Registers
          { mode = 'n', keys = '"' },
          { mode = 'x', keys = '"' },
          { mode = 'i', keys = '<C-r>' },
          { mode = 'c', keys = '<C-r>' },

          -- Window commands
          { mode = 'n', keys = '<C-w>' },

          -- `z` key
          { mode = 'n', keys = 'z' },
          { mode = 'x', keys = 'z' },
        },

        clues = {
          -- Enhance this by adding descriptions for <Leader> mapping groups
          miniclue.gen_clues.builtin_completion(),
          miniclue.gen_clues.g(),
          miniclue.gen_clues.marks(),
          miniclue.gen_clues.registers(),
          miniclue.gen_clues.windows(),
          miniclue.gen_clues.z(),
        },

        window = {delay = 500},
      })
    end
  },

  {
    'nvim-mini/mini.surround', version = '*' ,
    event = "VeryLazy",
    opts = {
      highlight_duration = 750,

      mappings = {
        add = '<Leader>ysa', -- Add surrounding in Normal and Visual modes
        delete = '<Leader>ysd', -- Delete surrounding
        find = '<Leader>ysf', -- Find surrounding (to the right)
        find_left = '<Leader>ysF', -- Find surrounding (to the left)
        highlight = '<Leader>ysh', -- Highlight surrounding
        replace = '<Leader>ysr', -- Replace surrounding
        suffix_last = 'l', -- Suffix to search with "prev" method
        suffix_next = 'n', -- Suffix to search with "next" method
      },

      -- Number of lines within which surrounding is searched
      n_lines = 20,

      -- Whether to respect selection type:
      -- - Place surroundings on separate lines in linewise mode.
      -- - Place surroundings on each line in blockwise mode.
      respect_selection_type = false,
      search_method = 'cover',
      silent = false,
    }
  },

  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = "markdown",
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
  },

  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      picker = {enabled=true},
      rename = {enabled=true},
      explorer = {enabled=true},
      input = {enabled=true},
      notifier = {enabled=true},
      quickfile = {enabled=true},
    },
    keys = {
      -- Top Pickers & Explorer
      { "<leader>f<space>", function() Snacks.picker.smart() end, desc = "Smart Find Files" },
      -- { "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
      -- { "<leader>/", function() Snacks.picker.grep() end, desc = "Grep" },
      { "<leader>f:", function() Snacks.picker.command_history() end, desc = "Command History" },
      { "<leader>n", function() Snacks.picker.notifications() end, desc = "Notification History" },
      { "<leader>e", function() Snacks.explorer() end, desc = "File Explorer" },
      -- find
      -- { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
      { "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Find Config File" },
      { "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files" },
      -- { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find Git Files" },
      -- { "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects" },
      { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent" },
      -- Grep
      -- { "<leader>sb", function() Snacks.picker.lines() end, desc = "Buffer Lines" },
      -- { "<leader>sB", function() Snacks.picker.grep_buffers() end, desc = "Grep Open Buffers" },
      { "<leader>fg", function() Snacks.picker.grep() end, desc = "Grep" },
      -- { "<leader>sw", function() Snacks.picker.grep_word() end, desc = "Visual selection or word", mode = { "n", "x" } },
      -- -- search
      -- { '<leader>s"', function() Snacks.picker.registers() end, desc = "Registers" },
      -- { '<leader>s/', function() Snacks.picker.search_history() end, desc = "Search History" },
      -- { "<leader>sa", function() Snacks.picker.autocmds() end, desc = "Autocmds" },
      -- { "<leader>sb", function() Snacks.picker.lines() end, desc = "Buffer Lines" },
      -- { "<leader>sc", function() Snacks.picker.command_history() end, desc = "Command History" },
      -- { "<leader>sC", function() Snacks.picker.commands() end, desc = "Commands" },
      -- { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
      -- { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
      -- { "<leader>sh", function() Snacks.picker.help() end, desc = "Help Pages" },
      -- { "<leader>sH", function() Snacks.picker.highlights() end, desc = "Highlights" },
      -- { "<leader>si", function() Snacks.picker.icons() end, desc = "Icons" },
      -- { "<leader>sj", function() Snacks.picker.jumps() end, desc = "Jumps" },
      -- { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
      -- { "<leader>sl", function() Snacks.picker.loclist() end, desc = "Location List" },
      -- { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
      -- { "<leader>sM", function() Snacks.picker.man() end, desc = "Man Pages" },
      -- { "<leader>sp", function() Snacks.picker.lazy() end, desc = "Search for Plugin Spec" },
      -- { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
      -- { "<leader>sR", function() Snacks.picker.resume() end, desc = "Resume" },
      -- { "<leader>su", function() Snacks.picker.undo() end, desc = "Undo History" },
      -- { "<leader>uC", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },
      -- -- LSP
      { "gd", function() Snacks.picker.lsp_definitions() end, desc = "Goto Definition" },
      -- { "gD", function() Snacks.picker.lsp_declarations() end, desc = "Goto Declaration" },
      -- { "gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
      { "grr", function() Snacks.picker.lsp_references({auto_confirm = false}) end, desc = "References (Snacks)", },

      -- { "gI", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
      -- { "gy", function() Snacks.picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition" },
      -- { "gai", function() Snacks.picker.lsp_incoming_calls() end, desc = "C[a]lls Incoming" },
      -- { "gao", function() Snacks.picker.lsp_outgoing_calls() end, desc = "C[a]lls Outgoing" },
      -- { "<leader>ss", function() Snacks.picker.lsp_symbols() end, desc = "LSP Symbols" },
      -- { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },
    },
  },
})

-- markdown-oxide installation
---- Merge capabilities with the default config from lsp/markdown_oxide.lua
local capabilities = vim.lsp.protocol.make_client_capabilities()

-- Use the function call form to MERGE (not replace) the config
vim.lsp.config('markdown_oxide', {
  -- Ensure that dynamicRegistration is enabled! This allows the LS to take into account actions like the
  -- Create Unresolved File code action, resolving completions for unindexed code blocks, ...
  capabilities = vim.tbl_deep_extend(
    'force',
    capabilities,
    {
      workspace = {
        didChangeWatchedFiles = {
          dynamicRegistration = true,
        },
      },
    }
  ),
})
vim.lsp.enable('markdown_oxide')

-- vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })

-- nvim-treesitter highlighting
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "<filetype>" },
  callback = function() vim.treesitter.start() end,
})

-- highlight on yank courtesy of MariaSolOs
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight on yank',
  callback = function()
    vim.hl.on_yank { higroup = 'IncSearch', timeout = 150 }
  end,
})

local function codelens_supported(bufnr)
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if c.server_capabilities and c.server_capabilities.codeLensProvider then
      return true
    end
  end
  return false
end

vim.api.nvim_create_autocmd(
  { 'TextChanged', 'InsertLeave', 'CursorHold', 'BufEnter' },
  {
    buffer = bufnr,
    callback = function()
      if codelens_supported(bufnr) then
        vim.lsp.codelens.enable(true)
      end
    end,
  }
)

-- Restart LSP upon :w so codelens updates file references
vim.api.nvim_create_autocmd("BufWrite", {
  callback = function()
      vim.cmd("lsp restart")
  end,
})

-- Command either jumps to linked note definition, or creates one through code_action
local function follow_markdown_link()
  local win = 0
  local before = vim.fn.gettagstack(win)

  vim.lsp.buf.definition()

  vim.defer_fn(function()
    local after = vim.fn.gettagstack(win)

    -- jumped successfully
    if after.curidx > before.curidx then
      return
    end

    -- create file
    vim.lsp.buf.code_action({
      filter = function(action)
        return action.title and action.title:match("Create")
      end,
      apply = true,
    })

    -- refresh LSP so new file is indexed
    vim.defer_fn(function()
      vim.cmd("lsp restart")
    end, 10)

  end, 10)
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.keymap.set("n", "gd", follow_markdown_link, { buffer = true }) 
  end,
})


vim.keymap.set("n", "<Leader>fnn", function()
  Snacks.picker.files({cwd = "~/notes"})
end, {desc = "Find notes by name"})

vim.keymap.set("n", "<Leader>fng", function()
  Snacks.picker.grep({cwd = "~/notes"})
end, {desc = "Grep notes"})
