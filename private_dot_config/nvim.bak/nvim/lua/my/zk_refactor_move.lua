-- lua/my/zk_refactor_move.lua
-- Safe helper to move a note and rewrite links across the vault.
-- - dry-run by default (opts.dry_run = true)
-- - use opts.dry_run = false to apply changes and move the file
-- - returns a summary table describing file and replacement counts

local M = {}
local fn = vim.fn
local log = vim.notify

-- basic path helpers
local function abspath(p) if not p or p == "" then return "" end return fn.fnamemodify(p, ":p"):gsub("/$", "") end
local function dirname(p) if not p or p == "" then return "./" end return p:match("(.*/)[^/]*$") or "./" end
local function split_path(p) local t = {} for part in p:gmatch("[^/]+") do t[#t+1] = part end return t end

-- compute relative path from directory of 'from_file' to 'to_file'
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

local function read_file(path) local ok, lines = pcall(fn.readfile, path) if not ok or not lines then return nil end return table.concat(lines, "\n") end
local function write_file(path, content) fn.writefile(vim.split(content, "\n", { plain = true }), path) end
local function all_md_files(notes_dir) notes_dir = abspath(notes_dir) local raw = fn.glob(notes_dir .. "/**/*.md") local out = {} for _, f in ipairs(vim.split(raw, "\n", { plain = true })) do if f ~= "" then out[#out+1] = f end end return out end
local function esc(s) return (s:gsub("([^%w])", "%%%1")) end
local function file_exists(p) return fn.filereadable(p) == 1 end

-- === replace_content_safe (same safe idea as earlier) ===
-- Replace only inside markdown paren links and wikilinks. Return new_content, changed, count
local function replace_content_safe(content, old_path_forms, basename_noext, new_form)
  local changed, total = false, 0
  table.sort(old_path_forms, function(a,b) return #a > #b end)
  -- 1) markdown paren links
  for _, old in ipairs(old_path_forms) do
    if old and old ~= "" then
      local pat = "%(" .. esc(old) .. "%)"
      local newc, n = content:gsub(pat, "(" .. new_form .. ")")
      if n > 0 then changed = true total = total + n content = newc end
    end
  end
  -- 2) wikilinks with path forms
  for _, old in ipairs(old_path_forms) do
    if old and old ~= "" then
      local wpat = "%[%[" .. esc(old) .. "%]%]"
      local newc, n = content:gsub(wpat, "[[" .. new_form .. "]]")
      if n > 0 then changed = true total = total + n content = newc end
    end
  end
  -- 3) wikilinks by bare basename
  if basename_noext and basename_noext ~= "" then
    local wpat2 = "%[%[" .. esc(basename_noext) .. "%]%]"
    local newc, n = content:gsub(wpat2, "[[" .. new_form .. "]]")
    if n > 0 then changed = true total = total + n content = newc end
  end
  return content, changed, total
end

-- === function: rewrite links in other files that point to old_abs ===
-- returns summary { total_files, total_replacements, per_file = { {file, replacements}, ... } }
function M.rewrite_external_links(notes_dir, old_abs, new_abs, opts)
  opts = opts or {}
  local dry_run = (opts.dry_run == nil) and true or opts.dry_run
  notes_dir = abspath(notes_dir); old_abs = abspath(old_abs); new_abs = abspath(new_abs)
  if notes_dir == "" or old_abs == "" or new_abs == "" then log("[zk_move] invalid paths", vim.log.levels.ERROR); return nil end

  local files = all_md_files(notes_dir)
  local summary = { total_files = 0, total_replacements = 0, per_file = {} }

  for _, f in ipairs(files) do
    if f ~= old_abs then -- skip the file itself (we handle internal links separately)
      local old_rel = relative_path(f, old_abs)
      local old_rel_noext = old_rel:gsub("%.md$", "")
      local old_path_forms = { old_rel, old_rel_noext, "./" .. old_rel, "./" .. old_rel_noext }
      local seen, dedup = {}, {}
      for _, v in ipairs(old_path_forms) do if v and v ~= "" and not seen[v] then seen[v]=true dedup[#dedup+1]=v end end
      old_path_forms = dedup
      local basename_noext = fn.fnamemodify(old_abs, ":t:r")
      local new_rel = relative_path(f, new_abs); local new_rel_noext = new_rel:gsub("%.md$", "") local new_form = (new_rel_noext ~= "" and new_rel_noext) or new_rel
      local text = read_file(f)
      if text then
        local new_text, changed, n = replace_content_safe(text, old_path_forms, basename_noext, new_form)
        if changed and n > 0 then
          summary.total_files = summary.total_files + 1
          summary.total_replacements = summary.total_replacements + n
          summary.per_file[#summary.per_file+1] = { file = f, replacements = n }
          if not dry_run then write_file(f, new_text) end
        end
      end
    end
  end

  return summary
end

-- === helper: resolve a link path (as seen in a file) into an absolute file path if it lives in notes_dir ===
-- link_text: text inside (...) or inside [[...]]; from_file: the file containing the link
-- returns absolute path to target (if resolvable inside notes_dir), or nil
local function resolve_link_to_abs(link_text, from_file, notes_dir)
  if not link_text or link_text == "" then return nil end
  -- ignore external links or anchors or absolute FS paths
  if link_text:match("^https?://") or link_text:match("^#") or link_text:match("^/") then return nil end

  -- if link_text contains parentheses? ignore
  local from_dir = dirname(from_file)
  local candidate = abspath(from_dir .. "/" .. link_text)
  if file_exists(candidate) then return candidate end
  -- try adding .md
  if not link_text:match("%.md$") then
    local cand2 = candidate .. ".md"
    if file_exists(cand2) then return cand2 end
  end

  -- If link_text is a bare name (no slashes), try to find a file under notes_dir with matching basename (prefer unique match)
  if not link_text:find("/") then
    local base = link_text
    if base:match("%.md$") then base = fn.fnamemodify(base, ":t:r") end
    -- search for files whose basename (noext) equals base
    local raw = fn.glob(abspath(notes_dir) .. "/**/" .. base .. "*.md")
    local parts = vim.split(raw, "\n", { plain = true })
    if #parts == 1 and parts[1] ~= "" then return abspath(parts[1]) end
    -- if many matches, return nil (ambiguous)
    return nil
  end

  return nil
end

-- === update internal links inside the moved file after it is moved ===
-- Reads the content from old_abs (or current file if old_abs has been moved), finds links inside that file,
-- resolves them to absolute targets and rewrites them relative to new_abs location.
-- Returns { replacements = n, per_link = { {old_text, new_text, count}, ... } }
function M.update_internal_links(old_abs, new_abs, notes_dir, opts)
  opts = opts or {}
  local dry_run = (opts.dry_run == nil) and true or opts.dry_run
  notes_dir = abspath(notes_dir); old_abs = abspath(old_abs); new_abs = abspath(new_abs)
  -- read content from the file *as it currently exists on disk before move*.
  local orig_content = read_file(old_abs) or read_file(new_abs) -- try new_abs if old_abs already moved
  if not orig_content then return nil end

  local total = 0
  local changes = {}
  local content = orig_content

  -- pattern: markdown paren links: ](path)
  for link in content:gmatch("%]%(([^%)]+)%)") do
    local target_abs = resolve_link_to_abs(link, old_abs, notes_dir)
    if target_abs then
      local new_rel = relative_path(new_abs, target_abs)
      local new_rel_noext = new_rel:gsub("%.md$", "")
      local newform = (new_rel_noext ~= "" and new_rel_noext) or new_rel
      local pat = "%]" .. "%(" .. esc(link) .. "%)" -- match ](link)
      local newpiece = "](" .. newform .. ")"
      local newc, n = content:gsub("%(" .. esc(link) .. "%)", "(" .. newform .. ")")
      if n > 0 then
        total = total + n
        content = newc
        changes[#changes+1] = { old = link, new = newform, count = n }
      end
    end
  end

  -- pattern: wikilinks [[...]]
  for link in content:gmatch("%[%[([^%]]+)%]%]") do
    -- skip alias forms like 'target|alias' => take left part
    local main = link:match("^[^|]+") or link
    main = (main or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local target_abs = resolve_link_to_abs(main, old_abs, notes_dir)
    if target_abs then
      local new_rel = relative_path(new_abs, target_abs)
      local new_rel_noext = new_rel:gsub("%.md$", "")
      local newform = (new_rel_noext ~= "" and new_rel_noext) or new_rel
      local wpat = "%[%[" .. esc(link) .. "%]%]"
      local newc, n = content:gsub(wpat, "[[" .. newform .. "]]")
      if n > 0 then
        total = total + n
        content = newc
        changes[#changes+1] = { old = link, new = newform, count = n }
      end
    end
  end

  -- write back if not dry_run
  if total > 0 and not dry_run then
    -- if the file was actually moved and no longer at old_abs, write to new_abs
    local target_write = file_exists(old_abs) and old_abs or new_abs
    write_file(target_write, content)
  end

  return { replacements = total, changes = changes }
end

-- === main move_and_rewrite helper ===
-- opts: { dry_run = true/false, use_mv_cmd = true/false }
function M.move_and_rewrite(notes_dir, old_abs, new_abs, opts)
  opts = opts or {}
  local dry_run = (opts.dry_run == nil) and true or opts.dry_run
  notes_dir = abspath(notes_dir); old_abs = abspath(old_abs); new_abs = abspath(new_abs)
  if notes_dir == "" or old_abs == "" or new_abs == "" then log("[zk_move] invalid paths", vim.log.levels.ERROR); return nil end

  -- 1) external links dry-run/apply
  local ext_summary = M.rewrite_external_links(notes_dir, old_abs, new_abs, { dry_run = dry_run })

  -- 2) internal links in moved file (we use old_abs content to resolve relative targets)
  local internal_summary = M.update_internal_links(old_abs, new_abs, notes_dir, { dry_run = dry_run })

  -- 3) perform actual move if requested
  local moved = false
  local move_err = nil
  if not dry_run then
    -- create target dir
    local target_dir = dirname(new_abs)
    fn.mkdir(target_dir, "p")
    -- try os.rename first
    local ok, err = os.rename(old_abs, new_abs)
    if not ok then
      if opts.use_mv_cmd == false then move_err = err
      else
        -- fallback to shell mv (handles cross-device)
        local cmd = { "mv", old_abs, new_abs }
        fn.system(cmd)
        if fn.vshellerror ~= 0 then move_err = "mv cmd failed: " .. tostring(fn.vshellerror) else moved = true end
      end
    else
      moved = true
    end
  end

  local result = {
    external = ext_summary,
    internal = internal_summary,
    moved = moved,
    move_err = move_err,
    dry_run = dry_run,
  }

  -- optionally reindex via zk plugin if available
  if not dry_run then pcall(function() require("zk.api").index(new_abs, {}, function() end) end) end

  local msg = string.format("[zk_move] %s: external files %d replacements, internal %d replacements, moved=%s",
    dry_run and "Dry-run" or "Done",
    (ext_summary and ext_summary.total_replacements) or 0,
    (internal_summary and internal_summary.replacements) or 0,
    tostring(moved)
  )
  log(msg, vim.log.levels.INFO)
  return result
end

return M
