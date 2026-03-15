-- lua/my/zk_refactor_minimal_fixed.lua
-- Minimal, dependency-free helper to update links when a note is moved/renamed.
-- Dry-run by default. Use opts = { dry_run = false } to apply changes.

local M = {}
local fn = vim.fn

local function abspath(p)
  if not p or p == "" then return "" end
  return fn.fnamemodify(p, ":p"):gsub("/$", "")
end

local function dirname(p)
  if not p or p == "" then return "./" end
  return p:match("(.*/)[^/]*$") or "./"
end

local function split_path(p)
  local t = {}
  for part in p:gmatch("[^/]+") do t[#t+1] = part end
  return t
end

-- compute relative path from directory of 'from_file' to 'to_file'
local function relative_path(from_file, to_file)
  local from_dir = dirname(abspath(from_file))
  local a = split_path(abspath(from_dir))
  local b = split_path(abspath(to_file))

  local i = 1
  while a[i] and b[i] and a[i] == b[i] do i = i + 1 end

  local up = ""
  for j = i, #a do up = up .. "../" end

  local down_list = {}
  for j = i, #b do table.insert(down_list, b[j]) end
  local down = table.concat(down_list, "/")

  if down ~= "" then
    return up .. down
  else
    return up:gsub("/$", "")
  end
end

local function read_file(path)
  local ok, lines = pcall(fn.readfile, path)
  if not ok or not lines then return nil end
  return table.concat(lines, "\n")
end

local function write_file(path, content)
  local lines = vim.split(content, "\n", { plain = true })
  fn.writefile(lines, path)
end

local function all_md_files(notes_dir)
  notes_dir = abspath(notes_dir)
  local pattern = notes_dir .. "/**/*.md"
  local raw = fn.glob(pattern)
  local out = {}
  for _, f in ipairs(vim.split(raw, "\n", { plain = true })) do
    if f ~= "" then table.insert(out, f) end
  end
  return out
end

local function esc_pat(s)
  return s:gsub("([^%w])", "%%%1")
end

-- Perform replacements (safe):
-- 1) Replace markdown parentheses links: ](OLD) -> (NEW)
-- 2) Replace wikilinks: [[OLD]] -> [[NEW]]
-- We avoid any global/fallback replacement that can match inside newly inserted text.
local function replace_content_safe(orig_content, old_path_forms, basename_noext, new_form)
  local content = orig_content
  local changed = false

  -- Order long->short to prefer longer path matches first
  table.sort(old_path_forms, function(a,b) return #a > #b end)

  -- 1) Markdown-style parentheses links (path forms only)
  for _, old in ipairs(old_path_forms) do
    if old and old ~= "" then
      local pat = "%(" .. esc_pat(old) .. "%)"
      if content:find(pat, 1) then
        content = content:gsub(pat, "(" .. new_form .. ")")
        changed = true
      end
    end
  end

  -- 2) Wikilinks:
  -- We replace wikilinks that reference either a path (../+/x) or just the basename (no ext)
  -- Replace path-like wikilinks first
  for _, old in ipairs(old_path_forms) do
    if old and old ~= "" then
      local wpat = "%[%[" .. esc_pat(old) .. "%]%]"
      if content:find(wpat, 1) then
        content = content:gsub(wpat, "[[" .. new_form .. "]]")
        changed = true
      end
    end
  end

  -- Then replace bare wikilink names like [[basename-noext]] (only inside [[ ]])
  if basename_noext and basename_noext ~= "" then
    local wpat2 = "%[%[" .. esc_pat(basename_noext) .. "%]%]"
    if content:find(wpat2, 1) then
      content = content:gsub(wpat2, "[[" .. new_form .. "]]")
      changed = true
    end
  end

  return content, changed
end

--- Public:
-- notes_dir: path to vault (eg "~/notes")
-- old_abs: absolute path to original note (eg "/home/slap/notes/+/file.md")
-- new_abs: absolute path to new note location
-- opts = { dry_run = true/false }
function M.rewrite_links_for_move(notes_dir, old_abs, new_abs, opts)
  opts = opts or {}
  local dry_run = opts.dry_run == nil and true or opts.dry_run

  notes_dir = abspath(notes_dir)
  old_abs   = abspath(old_abs)
  new_abs   = abspath(new_abs)

  if notes_dir == "" or old_abs == "" or new_abs == "" then
    vim.notify("[zk_refactor_fixed] Invalid paths provided", vim.log.levels.ERROR)
    return {}
  end

  local files = all_md_files(notes_dir)
  local changed_files = {}

  for _, f in ipairs(files) do
    -- compute forms we expect to find in 'f' that point to old_abs
    local old_rel = relative_path(f, old_abs)            -- with .md
    local old_rel_noext = old_rel:gsub("%.md$", "")      -- without .md

    local old_path_forms = {
      old_rel,
      old_rel_noext,
      "./" .. old_rel,
      "./" .. old_rel_noext,
    }

    -- dedupe
    local seen = {}
    local dedup = {}
    for _, v in ipairs(old_path_forms) do
      if v and v ~= "" and not seen[v] then seen[v] = true table.insert(dedup, v) end
    end
    old_path_forms = dedup

    local basename_noext = fn.fnamemodify(old_abs, ":t:r")

    -- choose new_form without extension if possible
    local new_rel = relative_path(f, new_abs)
    local new_rel_noext = new_rel:gsub("%.md$", "")
    local new_form = (new_rel_noext ~= "" and new_rel_noext) or new_rel

    local content = read_file(f)
    if content then
      local new_content, did = replace_content_safe(content, old_path_forms, basename_noext, new_form)
      if did then
        table.insert(changed_files, f)
        if not dry_run then
          write_file(f, new_content)
        end
      end
    end
  end

  if dry_run then
    vim.notify(string.format("[zk_refactor_fixed] Dry-run: %d files would be updated", #changed_files), vim.log.levels.INFO)
  else
    vim.notify(string.format("[zk_refactor_fixed] Done: %d files updated", #changed_files), vim.log.levels.INFO)
  end

  return changed_files
end

return M
