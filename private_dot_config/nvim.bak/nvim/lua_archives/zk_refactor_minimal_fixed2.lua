-- lua/my/zk_refactor_minimal_fixed2.lua
-- Minimal helper to rewrite links when moving/renaming a note.
-- Counts occurrences, replaces only real links, dry-run by default.

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

-- relative path from dir(of from_file) to to_file
local function relative_path(from_file, to_file)
  local from_dir = dirname(abspath(from_file))
  local a = split_path(abspath(from_dir))
  local b = split_path(abspath(to_file))

  local i = 1
  while a[i] and b[i] and a[i] == b[i] do i = i + 1 end

  local up = ""
  for j = i, #a do up = up .. "../" end

  local down_t = {}
  for j = i, #b do down_t[#down_t+1] = b[j] end
  local down = table.concat(down_t, "/")

  return (down ~= "" and (up .. down)) or up:gsub("/$", "")
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
  local raw = fn.glob(notes_dir .. "/**/*.md")
  local out = {}
  for _, f in ipairs(vim.split(raw, "\n", { plain = true })) do
    if f ~= "" then out[#out+1] = f end
  end
  return out
end

local function esc(s) return (s:gsub("([^%w])", "%%%1")) end

-- Replace only inside markdown links ](old) and wikilinks [[old]]
-- Returns: new_content, changed(bool), replacements(int)
local function replace_content_safe(content, old_path_forms, basename_noext, new_form)
  local changed, total = false, 0

  -- Prefer longer strings first to avoid partial overlaps
  table.sort(old_path_forms, function(a, b) return #a > #b end)

  -- 1) Markdown links: ](OLD) -> ](NEW)
  for _, old in ipairs(old_path_forms) do
    if old and old ~= "" then
      local pat = "%(" .. esc(old) .. "%)"
      local newc, n = content:gsub(pat, "(" .. new_form .. ")")
      if n > 0 then changed = true; total = total + n; content = newc end
    end
  end

  -- 2) Wikilinks using path forms: [[OLD]] -> [[NEW]]
  for _, old in ipairs(old_path_forms) do
    if old and old ~= "" then
      local wpat = "%[%[" .. esc(old) .. "%]%]"
      local newc, n = content:gsub(wpat, "[[" .. new_form .. "]]")
      if n > 0 then changed = true; total = total + n; content = newc end
    end
  end

  -- 3) Wikilinks using bare name: [[basename]] -> [[NEW]]
  if basename_noext and basename_noext ~= "" then
    local wpat2 = "%[%[" .. esc(basename_noext) .. "%]%]"
    local newc, n = content:gsub(wpat2, "[[" .. new_form .. "]]")
    if n > 0 then changed = true; total = total + n; content = newc end
  end

  return content, changed, total
end

--- Public API
-- notes_dir: "~/notes"
-- old_abs  : "/abs/path/to/old.md"
-- new_abs  : "/abs/path/to/new.md"
-- opts: { dry_run = true/false } (default true)
-- Returns summary table with counts per file.
function M.rewrite_links_for_move(notes_dir, old_abs, new_abs, opts)
  opts = opts or {}
  local dry_run = (opts.dry_run == nil) and true or opts.dry_run

  notes_dir = abspath(notes_dir)
  old_abs   = abspath(old_abs)
  new_abs   = abspath(new_abs)
  if notes_dir == "" or old_abs == "" or new_abs == "" then
    vim.notify("[zk_refactor_minimal_fixed2] Invalid paths", vim.log.levels.ERROR)
    return { total_files = 0, total_replacements = 0, files = {} }
  end

  local files = all_md_files(notes_dir)
  local summary = { total_files = 0, total_replacements = 0, files = {} }

  for _, f in ipairs(files) do
    local old_rel        = relative_path(f, old_abs)         -- "dir/file.md"
    local old_rel_noext  = old_rel:gsub("%.md$", "")         -- "dir/file"
    local old_path_forms = {
      old_rel,
      old_rel_noext,
      "./" .. old_rel,
      "./" .. old_rel_noext,
    }
    -- dedupe
    local seen, dedup = {}, {}
    for _, v in ipairs(old_path_forms) do
      if v and v ~= "" and not seen[v] then seen[v] = true; dedup[#dedup+1] = v end
    end
    old_path_forms = dedup

    local basename_noext = fn.fnamemodify(old_abs, ":t:r")
    local new_rel        = relative_path(f, new_abs)
    local new_rel_noext  = new_rel:gsub("%.md$", "")
    local new_form       = (new_rel_noext ~= "" and new_rel_noext) or new_rel

    local text = read_file(f)
    if text then
      local new_text, changed, n = replace_content_safe(text, old_path_forms, basename_noext, new_form)
      if changed and n > 0 then
        summary.total_files = summary.total_files + 1
        summary.total_replacements = summary.total_replacements + n
        summary.files[#summary.files+1] = { file = f, replacements = n }
        if not dry_run then write_file(f, new_text) end
      end
    end
  end

  local msg = string.format(
    "[zk_refactor_minimal_fixed2] %s: %d files, %d replacements",
    dry_run and "Dry-run" or "Done",
    summary.total_files,
    summary.total_replacements
  )
  vim.notify(msg, vim.log.levels.INFO)
  return summary
end

return M
