-- lua/my/zk_move_ui.lua
-- Interactive UI wrapper around my.zk_refactor_move.move_and_rewrite
-- Provides :ZkMove and a default keymap <leader>zm

local M = {}

local fn = vim.fn
local api = vim.api
local has_telescope, telescope_builtin = pcall(require, "telescope.builtin")

-- normalize path (expand ~)
local function expand(p) return fn.fnamemodify(fn.expand(p), ":p"):gsub("/$", "") end

-- list directories under notes_dir (recursive)
local function list_folders(notes_dir)
  notes_dir = expand(notes_dir)
  -- glob with 0,1 returns a table of matches
  local dirs = fn.glob(notes_dir .. "/**/", 0, 1)
  local out = {}
  for _, d in ipairs(dirs) do
    if d ~= "" then
      -- show relative to notes_dir
      local rel = d:gsub("^" .. vim.pesc(notes_dir) .. "/", "")
      rel = rel:gsub("/$", "")  -- drop trailing slash
      if rel == "" then rel = "." end
      table.insert(out, { label = rel, path = d:gsub("/$", "") })
    end
  end
  -- make sure root is first
  table.insert(out, 1, { label = ".", path = notes_dir })
  return out
end

-- list note files under notes_dir (relative)
local function list_notes(notes_dir)
  notes_dir = expand(notes_dir)
  if has_telescope then
    -- If telescope is available, open it directly and return nil:
    -- The interactive path will be handled by telescope; this function caller must treat nil as "telescope handled it"
    return nil
  end
  local raw = fn.glob(notes_dir .. "/**/*.md", 0, 1)
  local out = {}
  for _, f in ipairs(raw) do
    local rel = f:gsub("^" .. vim.pesc(notes_dir) .. "/", "")
    table.insert(out, { label = rel, path = f })
  end
  return out
end

-- prompt helper that uses vim.ui.select or telescope
local function pick_from_list(prompt, items, opts, on_choice)
  opts = opts or {}
  if has_telescope and items == nil then
    -- telescope flow (caller expected to use telescope)
    -- use find_files with cwd=notes_dir, then call on_choice with selected entry path
    local pick_opts = { prompt_title = prompt, cwd = opts.cwd or nil, hidden = true }
    telescope_builtin.find_files(vim.tbl_deep_extend("force", pick_opts, { attach_mappings = function(_, map)
      map("i", "<CR>", function(prompt_bufnr)
        local selection = require("telescope.actions.state").get_selected_entry()
        require("telescope.actions").close(prompt_bufnr)
        if selection then on_choice(selection.cwd and selection.value or selection[1] or selection.value) end
      end)
      return true
    end }))
    return
  end

  local labels = {}
  for i, it in ipairs(items) do labels[i] = it.label end
  vim.ui.select(labels, { prompt = prompt }, function(choice, idx)
    if choice == nil then return end
    local item = items[idx]
    if item then on_choice(item) end
  end)
end

-- prompt user for new filename (default provided)
local function input_new_filename(default_name, callback)
  vim.ui.input({ prompt = "New filename (no path): ", default = default_name }, function(input)
    if not input or input == "" then callback(nil) else callback(input) end
  end)
end

-- confirmation prompt (Yes/No)
local function confirm_yes_no(msg)
  local choice = fn.confirm(msg, "&Yes\n&No", 2)
  return choice == 1
end

-- Build new absolute path given chosen folder and filename
local function build_new_abs(chosen_folder_path, new_filename)
  chosen_folder_path = expand(chosen_folder_path)
  -- ensure extension .md
  if not new_filename:match("%.md$") then new_filename = new_filename .. ".md" end
  return chosen_folder_path .. "/" .. new_filename
end

-- Main interactive move for the current buffer
function M.interactive_move(opts)
  opts = opts or {}
  local notes_dir = opts.notes_dir or "~/notes"
  local cur_file = fn.expand("%:p")
  if cur_file == "" then vim.notify("No file open", vim.log.levels.WARN); return end

  -- Step 1: Ask whether to pick a folder or choose an existing note
  vim.ui.select({ "Choose folder", "Choose existing note", "Enter full destination path" }, { prompt = "ZkMove: pick destination mode" }, function(choice)
    if not choice then return end

    if choice == "Choose folder" then
      local folders = list_folders(notes_dir)
      pick_from_list("Pick destination folder", folders, { cwd = notes_dir }, function(item)
        local default_name = fn.fnamemodify(cur_file, ":t")
        input_new_filename(default_name, function(newname)
          if not newname then vim.notify("Cancelled", vim.log.levels.INFO); return end
          local new_abs = build_new_abs(item.path, newname)
          -- dry-run preview
          local summary = require("my.zk_refactor_move").move_and_rewrite(notes_dir, cur_file, new_abs, { dry_run = true })
          vim.notify("Preview: " .. tostring((summary and summary.external and summary.external.total_replacements) or 0) .. " external replacements, internal: " .. tostring((summary and summary.internal and summary.internal.replacements) or 0), vim.log.levels.INFO)
          if confirm_yes_no("Apply move and rewrite?") then
            local res = require("my.zk_refactor_move").move_and_rewrite(notes_dir, cur_file, new_abs, { dry_run = false })
            vim.notify("Done. Open moved file? (Yes will open)", vim.log.levels.INFO)
            if confirm_yes_no("Open moved file now?") then
              api.nvim_command("edit " .. vim.fn.fnameescape(new_abs))
            end
          end
        end)
      end)

    elseif choice == "Choose existing note" then
      -- If telescope is available, use it (asynchronous) else use vim.ui.select with a list
      if has_telescope then
        -- open Telescope find_files; on selection, we get a path and use its dirname as target folder
        telescope_builtin.find_files({ prompt_title = "Pick existing note (destination folder will be note's folder)", cwd = expand(notes_dir), hidden = true, attach_mappings = function(_, map)
          map("i", "<CR>", function(prompt_bufnr)
            local pick = require("telescope.actions.state").get_selected_entry()
            require("telescope.actions").close(prompt_bufnr)
            if pick and pick.path or pick then
              local sel_path = pick.path or (pick.value and pick.value) or (pick.filename and pick.filename)
              if sel_path then
                local target_folder = fn.fnamemodify(sel_path, ":h")
                local default_name = fn.fnamemodify(cur_file, ":t")
                input_new_filename(default_name, function(newname)
                  if not newname then vim.notify("Cancelled", vim.log.levels.INFO); return end
                  local new_abs = build_new_abs(target_folder, newname)
                  local summary = require("my.zk_refactor_move").move_and_rewrite(notes_dir, cur_file, new_abs, { dry_run = true })
                  vim.notify("Preview: " .. tostring((summary and summary.external and summary.external.total_replacements) or 0) .. " external replacements, internal: " .. tostring((summary and summary.internal and summary.internal.replacements) or 0), vim.log.levels.INFO)
                  if confirm_yes_no("Apply move and rewrite?") then
                    local res = require("my.zk_refactor_move").move_and_rewrite(notes_dir, cur_file, new_abs, { dry_run = false })
                    if confirm_yes_no("Open moved file now?") then api.nvim_command("edit " .. vim.fn.fnameescape(new_abs)) end
                  end
                end)
              end
            end
          end)
          return true
        end })
      else
        -- fallback: present list of notes (may be large)
        local notes = list_notes(notes_dir)
        if not notes then vim.notify("No notes list available", vim.log.levels.ERROR); return end
        pick_from_list("Pick existing note", notes, { cwd = notes_dir }, function(item)
          local target_folder = fn.fnamemodify(item.path, ":h")
          local default_name = fn.fnamemodify(cur_file, ":t")
          input_new_filename(default_name, function(newname)
            if not newname then vim.notify("Cancelled", vim.log.levels.INFO); return end
            local new_abs = build_new_abs(target_folder, newname)
            local summary = require("my.zk_refactor_move").move_and_rewrite(notes_dir, cur_file, new_abs, { dry_run = true })
            vim.notify("Preview: " .. tostring((summary and summary.external and summary.external.total_replacements) or 0) .. " external replacements, internal: " .. tostring((summary and summary.internal and summary.internal.replacements) or 0), vim.log.levels.INFO)
            if confirm_yes_no("Apply move and rewrite?") then
              local res = require("my.zk_refactor_move").move_and_rewrite(notes_dir, cur_file, new_abs, { dry_run = false })
              if confirm_yes_no("Open moved file now?") then api.nvim_command("edit " .. vim.fn.fnameescape(new_abs)) end
            end
          end)
        end)
      end

    else -- Enter full destination path
      vim.ui.input({ prompt = "Full destination path (absolute or relative to notes root): ", default = "" }, function(input)
        if not input or input == "" then vim.notify("Cancelled", vim.log.levels.INFO); return end
        local new_abs = input
        if not fn.filereadable(new_abs) and not new_abs:match("^/") then
          -- treat as relative to notes_dir
          new_abs = expand(notes_dir) .. "/" .. input
        end
        new_abs = expand(new_abs)
        -- ask for confirmation
        local summary = require("my.zk_refactor_move").move_and_rewrite(notes_dir, cur_file, new_abs, { dry_run = true })
        vim.notify("Preview: " .. tostring((summary and summary.external and summary.external.total_replacements) or 0) .. " external replacements, internal: " .. tostring((summary and summary.internal and summary.internal.replacements) or 0), vim.log.levels.INFO)
        if confirm_yes_no("Apply move and rewrite?") then
          local res = require("my.zk_refactor_move").move_and_rewrite(notes_dir, cur_file, new_abs, { dry_run = false })
          if confirm_yes_no("Open moved file now?") then api.nvim_command("edit " .. vim.fn.fnameescape(new_abs)) end
        end
      end)
    end
  end)
end

-- setup helper: registers :ZkMove command and default keymap (if provided)
function M.setup(opts)
  opts = opts or {}
  local keymap = opts.keymap or "<leader>zm"
  local notes_dir = opts.notes_dir or "~/notes"

  -- command
  api.nvim_create_user_command("ZkMove", function()
    M.interactive_move({ notes_dir = notes_dir })
  end, { desc = "Interactive move/rename note with zk-aware link rewriting" })

  -- keymap (buffer-local? global is OK)
  vim.keymap.set("n", keymap, function() M.interactive_move({ notes_dir = notes_dir }) end, { desc = "ZkMove interactive", noremap = true, silent = true })
end

return M
