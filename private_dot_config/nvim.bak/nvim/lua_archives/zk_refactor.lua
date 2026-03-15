-- lua/my/zk_refactor.lua
local M = {}

local function split_path(p)
  local t = {}
  for part in p:gmatch("[^/]+") do t[#t+1] = part end
  return t
end

local function dirname(path)
  return path:match("(.*/)[^/]*$") or "./"
end

-- Normalize to absolute path (no trailing slash)
local function abspath(p)
  local ok, res = pcall(vim.fn.fnamemodify, p, ":p")
  if not ok then return p end
  res = res:gsub("/$", "")
  return res
end

-- compute relative path from 'from_file' to 'to_file'
local function relative_path(from_file, to_file)
  local from_dir = dirname(abspath(from_file))
  local a = split_path(abspath(from_dir))
  local b = split_path(abspath(to_file))

  -- find common prefix length
  local i = 1
  while a[i] and b[i] and a[i] == b[i] do i = i + 1 end
  local up = ""
  for j = i, #a do up = up .. "../" end
  local down = table.concat(vim.list_slice(b, i, #b), "/")
  if down ~= "" then
    return (up .. down)
  else
    -- target is the directory itself, uncommon for file target; return up .. last part
    return (up:gsub("/$", ""))
  end
end

-- Escape .-magic for gsub pattern
local function escape_lua_pattern(s)
  return s:gsub("([^%w])", "%%%1")
end

-- Read whole file as string
local function read_file(path)
  local lines = vim.fn.readfile(path)
  if not lines then return nil end
  return table.concat(lines, "\n")
end

-- Write whole file from string
local function write_file(path, content)
  local lines = vim.split(content, "\n", { plain = true })
  vim.fn.writefile(lines, path)
end

-- Find all markdown files under notes_dir (absolute)
local function all_md_files(notes_dir)
  notes_dir = abspath(notes_dir)
  -- use vim.fn.globpath to recurse; true returns a list
  local pattern = notes_dir .. "/**/*.md"
  local files = vim.split(vim.fn.glob(pattern), "\n", { plain = true })
  local out = {}
  for _, f in ipairs(files) do
    if f ~= "" then table.insert(out, f) end
  end
  return out
end

-- main function: given old_abs (old absolute path to note) and new_abs (new absolute path),
-- update links in all files under notes_dir. dry_run = true to only preview.
function M.rewrite_links_for_move(notes_dir, old_abs, new_abs, opts)
  opts = opts or {}
  local dry_run = opts.dry_run == nil and true or opts.dry_run -- default to dry-run
  notes_dir = abspath(notes_dir)
  old_abs = abspath(old_abs)
  new_abs = abspath(new_abs)

  local files = all_md_files(notes_dir)
  local changed = {}
  local touched_count = 0

  for _, f in ipairs(files) do
    -- compute what a link from file f to old_abs would look like, and to new_abs
    local old_rel = relative_path(f, old_abs)
    local new_rel = relative_path(f, new_abs)

    -- sometimes links include ./ at front; also check absolute basename matches
    local old_basename = vim.fn.fnamemodify(old_abs, ":t") -- filename
    local candidates = {
      old_rel,
      "./" .. old_rel,
      old_basename,
      "../" .. old_basename, -- sometimes people use simple parent links
    }

    local content = read_file(f)
    if content then
      local orig = content
      local new_content = content

      for _, cand in ipairs(candidates) do
        if #cand > 0 then
          -- Replace links in Markdown style: ](<cand>)  and variants
          local pat = "%]%(" .. escape_lua_pattern(cand) .. "%)"
          local repl = "](" .. new_rel .. ")"
          new_content = new_content:gsub(pat, repl)

          -- Replace plain occurrences inside wikilinks or parentheses as fallback
          local pat2 = escape_lua_pattern(cand)
          new_content = new_content:gsub(pat2, new_rel)
        end
      end

      if new_content ~= orig then
        touched_count = touched_count + 1
        table.insert(changed, { file = f, old = old_rel, new = new_rel })
        if not dry_run then
          write_file(f, new_content)
        end
      end
    end
  end

  -- Report
  if dry_run then
    vim.notify(string.format("[zk_refactor] Dry-run: %d files would be updated", touched_count), vim.log.levels.INFO)
  else
    vim.notify(string.format("[zk_refactor] Done: %d files updated", touched_count), vim.log.levels.INFO)
  end

  return changed
end

-- convenience wrapper: move a file and then update links.
-- move_func may be nil (uses os.rename) or a function(old,new)->bool
function M.move_and_rewrite(notes_dir, old_abs, new_abs, opts)
  opts = opts or {}
  local use_os = opts.use_os_move ~= false
  -- make absolute
  old_abs = abspath(old_abs)
  new_abs = abspath(new_abs)

  -- do a dry run first (default)
  local dry_run = opts.dry_run == nil and true or opts.dry_run
  local preview = M.rewrite_links_for_move(notes_dir, old_abs, new_abs, { dry_run = true })

  if dry_run then
    vim.print(preview)
    vim.notify("[zk_refactor] Dry-run complete. Set dry_run=false to execute.", vim.log.levels.WARN)
    return preview
  end

  -- perform actual move
  local ok, err
  if use_os then
    ok = os.rename(old_abs, new_abs)
    if not ok then err = "os.rename failed" end
  else
    if type(opts.move_func) == "function" then
      ok = opts.move_func(old_abs, new_abs)
    else
      ok = os.rename(old_abs, new_abs)
    end
  end

  if not ok then
    vim.notify("[zk_refactor] move failed: " .. tostring(err), vim.log.levels.ERROR)
    return nil
  end

  -- rewrite links for real
  local changed = M.rewrite_links_for_move(notes_dir, old_abs, new_abs, { dry_run = false })
  -- optionally re-index via zk plugin API if present
  pcall(function() require("zk.api").index(new_abs, {}, function() end) end)
  return changed
end

return M
