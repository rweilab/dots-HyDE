return {
  -- 1. Orgmode core plugin
  {
    "nvim-orgmode/orgmode",
    -- ft = { "org" },       -- load only for .org files
    dependencies = {"danilshvalov/org-modern.nvim"},
    config = function()
      local Menu = require("org-modern.menu")

      require("orgmode").setup({
        org_agenda_files = "~/org/**/*",
        org_default_notes_file = "~/org/inbox.org",
        ui = {
          menu = {
            handler = function(data)
              Menu:new({
                window = {
                  margin = { 1, 0, 1, 0 },
                  padding = { 0, 1, 0, 1 },
                  title_pos = "center",
                  border = "single",
                  zindex = 1000,
                },
                icons = {
                  separator = "➜",
                },
              }):open(data)
            end,
          },
        },
      })
    end,
  },

  -- 2. Org-bullets (pretty bullets in headlines)
  {
    "akinsho/org-bullets.nvim",
    ft = { "org" },
    config = function()
      require("org-bullets").setup()
    end,
  },

  -- 3. Headlines.nvim (optional visual enhancement for headings)
  {
    "lukas-reineke/headlines.nvim",
    ft = { "org" },
    dependencies = "nvim-treesitter/nvim-treesitter",
    config = true,  -- uses default setup
  },

  -- 4. Org-modern (modern UI / menu is used in orgmode setup above)
  {
    "danilshvalov/org-modern.nvim",
    ft = { "org" },
    -- config = true, -- default setup
  },
  {
    "nvim-orgmode/telescope-orgmode.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-orgmode/orgmode",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("telescope").load_extension("orgmode")

      vim.keymap.set("n", "<leader>r", require("telescope").extensions.orgmode.refile_heading)
      vim.keymap.set("n", "<leader>foh", require("telescope").extensions.orgmode.search_headings)
      vim.keymap.set("n", "<leader>li", require("telescope").extensions.orgmode.insert_link)
    end,
  },
}
