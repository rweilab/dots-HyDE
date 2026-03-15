-- lua/my/zk_refactor_fixed.lua
local M = {}

local function abspath(p) return vim.fn.fnamemodify(p, ":p"):gsub("/$", "") end
local function dirname(path) return path:match("(.*/)[^/]*$") or "./" end
local function split_path(p)
  local t = {}
  for part in p:gmatch("[^/]+") do t[#t+1] = part end
  return t
end

local function relative_path(from_file, to_file)
  local from_dir = dirname(abspath(from_file))
  local a = split_path(abspath(from_dir))
  local b = split_path(abspath(to_file))
  local i = 1
  while a[i] and b[i] and a[i] == b[i] do i = i + 1 end
  local up = ""
  for j = i, #a do up = up .. "../" end
  local down = table.concat(vim.list_slice(b, i, #b), "/")
  if down ~= "" then
    return (up .. down)
  else
    return up:gsub("/$", "")
  end
end

local function escape_lua_pattern(s) return s:gsub("([^%w])", "%%%1") end
local function read_file(path) return table.concat(vim.fn.readfile(path), "\n") end
local function write_file(path, content) vim.fn.writefile(vim.split(content, "\n", { plain = true }), path) end

local function all_md_files(notes_dir)
  notes_dir = abspath(notes_dir)
  local pattern = notes_dir .. "/**/*.md"
  local raw = vim.fn.glob(pattern)
  local files = {}
  for f in vim.split(raw, "\n", { plain = true }) do if f ~= "" then table.insert(files, f) end end
  return files
end

-- Produce candidates: with/without .md, with ./ prefix and basename-only forms
local function make_candidates(old_abs)
  local cand = {}
  local basename = vim.fn.fnamemodify(old_abs, ":t")          -- e.g. school-shopping-...md
  local basename_noext = vim.fn.fnamemodify(old_abs, ":t:r") -- drop .md
  table.insert(cand, basename)
  table.insert(cand, basename_noext)
  -- also allow percent-encoding of + (rare) - include it as fallback
  table.insert(cand, basename:gsub("%+", "%%2B"))
  table.insert(cand, basename_noext:gsub("%+", "%%2B"))
  return { basename = basename, basename_noext = basename_noext, list = cand }
end

-- Replace occurrences inside markdown links (...) and wikilinks [[...]]
local function replace_in_content(content, old_link_forms, new_link_form, debug, file)
  local changed = false
  local debug_hits = {}

  -- 1) Markdown-style parentheses links: e.g. ](../+/foo) or ](../+/foo.md)
  for _, old in ipairs(old_link_forms) do
    if #old > 0 then
      local pat = "%(" .. escape_lua_pattern(old) .. "%)"
      if content:find(pat, 1) then
        content = content:gsub(pat, "(" .. new_link_form .. ")")
        changed = true
        table.insert(debug_hits, { type = "md_paren", old = old })
      end
    end
  end

  -- 2) Wikilinks like [[name]] or [[path/to/name]]
  for _, old in ipairs(old_link_forms) do
    if #old > 0 then
      -- match inside [[...]] - try both basename_noext and path-like candidates
      local wikipat = "%[%[" .. escape_lua_pattern(old) .. "%]%]"
      if content:find(wikipat, 1) then
        content = content:gsub(wikipat, "[[" .. new_link_form .. "]]")
        changed = true
        table.insert(debug_hits, { type = "wikilink", old = old })
      end
    end
  end

  -- 3) Fallback: plain occurrences of the path (rare, but sometimes used)
  for _, old in ipairs(old_link_forms) do
    if #old > 0 and content:find(escape_lua_pattern(old), 1, true) then
      content = content:gsub(escape_lua_pattern(old), new_link_form)
      changed = true
      table.insert(debug_hits, { type = "plain", old = old })
    end
  end

  if debug and #debug_hits > 0 then
    vim.print("DEBUG hits in file:", file, debug_hits)
  end

  return content, changed
end

-- core function
function M.rewrite_links_for_move(notes_dir, old_abs, new_abs, opts)
  opts = opts or {}
  local dry_run = opts.dry_run == nil and true or opts.dry_run
  local debug   = opts.debug == true
  notes_dir = abspath(notes_dir)
  old_abs = abspath(old_abs)
  new_abs = abspath(new_abs)

  local files = all_md_files(notes_dir)
  local changed = {}
  local touched_count = 0

  -- For each file, compute the relative strings we expect to find and replace
  for _, f in ipairs(files) do
    local old_rel = relative_path(f, old_abs)            -- e.g. ../+/school-shopping-...md
    local new_rel = relative_path(f, new_abs)
    local old_rel_noext = old_rel:gsub("%.md$", "")
    local new_rel_noext = new_rel:gsub("%.md$", "")

    -- candidate forms to look for in the file text
    local old_candidates = {
      old_rel,
      old_rel_noext,
      "./" .. old_rel,
      "./" .. old_rel_noext,
      vim.fn.fnamemodify(old_abs, ":t"),
      vim.fn.fnamemodify(old_abs, ":t:r"),
    }

    -- make unique
    local uniq = {}
    local old_list = {}
    for _, v in ipairs(old_candidates) do
      if v and v ~= "" and not uniq[v] then uniq[v] = true table.insert(old_list, v) end
    end

    local new_pref = new_rel_noext ~= "" and new_rel_noext or new_rel

    local content = read_file(f)
    if content then
      local new_content, ok = replace_in_content(content, old_list, new_pref, debug, f)
      if ok then
        touched_count = touched_count + 1
        table.insert(changed, { file = f, old = old_list, new = new_pref })
        if not dry_run then
          write_file(f, new_content)
        end
      end
    end
  end

  if dry_run then
    vim.notify(string.format("[zk_refactor_fixed] Dry-run: %d files would be updated", touched_count), vim.log.levels.INFO)
  else
    vim.notify(string.format("[zk_refactor_fixed] Done: %d files updated", touched_count), vim.log.levels.INFO)
  end

  return changed
end

return M
