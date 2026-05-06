local function fetch_json(url, on_result)
  local stdout = {}
  vim.fn.jobstart({ "curl", "--compressed", "-fsSL", url }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      stdout = data
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        if code ~= 0 then
          on_result(nil, "curl exited with code " .. code)
          return
        end
        local body = table.concat(stdout, "\n")
        local ok, decoded = pcall(vim.json.decode, body)
        if not ok then
          on_result(nil, "failed to decode JSON: " .. tostring(decoded))
          return
        end
        on_result(decoded, nil)
      end)
    end,
  })
end

local function compare_versions(a, b)
  local function strip_build(v) return (v:gsub("%+.*$", "")) end
  a, b = strip_build(a), strip_build(b)

  local function split(v)
    local main, pre = v:match("^([^%-]+)%-?(.*)$")
    return main or v, pre or ""
  end
  local a_main, a_pre = split(a)
  local b_main, b_pre = split(b)

  local function parts(s)
    local t = {}
    for n in s:gmatch("[^%.]+") do
      table.insert(t, tonumber(n) or n)
    end
    return t
  end

  local pa, pb = parts(a_main), parts(b_main)
  for i = 1, math.max(#pa, #pb) do
    local x, y = pa[i] or 0, pb[i] or 0
    if type(x) ~= type(y) then x, y = tostring(x), tostring(y) end
    if x < y then return -1 end
    if x > y then return 1 end
  end

  if a_pre == "" and b_pre ~= "" then return 1 end
  if a_pre ~= "" and b_pre == "" then return -1 end
  if a_pre < b_pre then return -1 end
  if a_pre > b_pre then return 1 end
  return 0
end

local function is_prerelease(v)
  return v:match("%-") ~= nil
end

local function fetch_registration(pkg_name, on_result)
  local url = "https://api.nuget.org/v3/registration5-gz-semver2/"
    .. pkg_name:lower() .. "/index.json"
  fetch_json(url, function(idx, err)
    if err then on_result(nil, err) return end

    local pages = idx.items or {}
    local entries = {}
    local pending = 0
    local errored = false

    local function add_inline(page)
      for _, leaf in ipairs(page.items or {}) do
        local ce = leaf.catalogEntry
        if ce then
          table.insert(entries, {
            version = ce.version,
            releaseNotes = ce.releaseNotes,
            published = ce.published,
          })
        end
      end
    end

    local function maybe_done()
      if pending == 0 and not errored then on_result(entries, nil) end
    end

    if #pages == 0 then on_result(entries, nil) return end

    for _, page in ipairs(pages) do
      if page.items then
        add_inline(page)
      else
        pending = pending + 1
        fetch_json(page["@id"], function(sub, sub_err)
          if errored then return end
          if sub_err then
            errored = true
            on_result(nil, sub_err)
            return
          end
          add_inline(sub)
          pending = pending - 1
          maybe_done()
        end)
      end
    end

    maybe_done()
  end)
end

local function open_info_window(pkg, kind)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "markdown"

  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.7)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " " .. pkg.name .. " ",
  })
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true

  local function set_lines(text_lines)
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, text_lines)
    vim.bo[buf].modifiable = false
  end

  set_lines({ "Loading release notes for " .. pkg.name .. "..." })

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "q", close, opts)
  vim.keymap.set("n", "<Esc>", close, opts)

  local function notes_to_lines(notes)
    if not notes or notes == vim.NIL then return { "_(no release notes)_" } end
    local s = tostring(notes)
    if s == "" then return { "_(no release notes)_" } end
    local out = {}
    for line in (s .. "\n"):gmatch("([^\n]*)\n") do
      table.insert(out, line)
    end
    return out
  end

  fetch_registration(pkg.name, function(entries, err)
    if not vim.api.nvim_buf_is_valid(buf) then return end
    if err then
      set_lines({
        "# " .. pkg.name,
        "",
        "Failed to fetch release notes:",
        "",
        err,
        "",
        "Check your network connection.",
      })
      return
    end

    local out = { "# " .. pkg.name, "" }

    if kind == "vulnerable" then
      table.insert(out, "**Resolved version:** " .. pkg.resolved)
      table.insert(out, "**Severity:** " .. pkg.severity)
      table.insert(out, "**Advisory:** " .. pkg.advisory)
      table.insert(out, "")
      table.insert(out, "## Release notes for " .. pkg.resolved)
      table.insert(out, "")
      local found
      for _, e in ipairs(entries) do
        if e.version == pkg.resolved then found = e break end
      end
      if found then
        for _, l in ipairs(notes_to_lines(found.releaseNotes)) do
          table.insert(out, l)
        end
      else
        table.insert(out, "_(version not found in registry)_")
      end
    else
      local include_pre = is_prerelease(pkg.latest)
      local matches = {}
      for _, e in ipairs(entries) do
        if include_pre or not is_prerelease(e.version) then
          if compare_versions(e.version, pkg.current) > 0
            and compare_versions(e.version, pkg.latest) <= 0 then
            table.insert(matches, e)
          end
        end
      end
      table.sort(matches, function(a, b)
        return compare_versions(a.version, b.version) > 0
      end)

      table.insert(out, string.format("**%s → %s** (%d release(s))",
        pkg.current, pkg.latest, #matches))
      table.insert(out, "")

      if #matches == 0 then
        table.insert(out, "_No releases found between current and latest._")
      else
        for _, e in ipairs(matches) do
          local date = ""
          if e.published and e.published ~= vim.NIL then
            date = " (" .. tostring(e.published):sub(1, 10) .. ")"
          end
          table.insert(out, "## " .. e.version .. date)
          table.insert(out, "")
          for _, l in ipairs(notes_to_lines(e.releaseNotes)) do
            table.insert(out, l)
          end
          table.insert(out, "")
        end
      end
    end

    set_lines(out)
  end)
end

local function find_csprojs_for_package(pkg_name)
  local csprojs = vim.fn.glob("**/*.csproj", false, true)
  local matches = {}
  for _, proj in ipairs(csprojs) do
    for _, line in ipairs(vim.fn.readfile(proj)) do
      if line:find(pkg_name, 1, true) then
        table.insert(matches, proj)
        break
      end
    end
  end
  return matches
end

local function open_nuget_popup(vulnerable, outdated)
  local buf = vim.api.nvim_create_buf(false, true)
  local ns = vim.api.nvim_create_namespace("nuget_check")

  local lines = {}
  local pkg_map = {}
  local first_pkg_line = nil

  -- Vulnerable section
  if #vulnerable > 0 then
    local name_width = #"Package"
    for _, pkg in ipairs(vulnerable) do
      if #pkg.name > name_width then name_width = #pkg.name end
    end
    name_width = name_width + 2

    table.insert(lines, "  ⚠ Vulnerable Packages")
    table.insert(lines, "")
    local hdr_fmt = "  %-" .. name_width .. "s %-10s  %-8s  %s"
    table.insert(lines, string.format(hdr_fmt, "Package", "Resolved", "Severity", "Advisory"))
    table.insert(lines, "  " .. string.rep("─", name_width + 50))

    local fmt = "  %-" .. name_width .. "s %-10s  %-8s  %s"
    for _, pkg in ipairs(vulnerable) do
      local line = string.format(fmt, pkg.name, pkg.resolved, pkg.severity, pkg.advisory)
      table.insert(lines, line)
      pkg_map[#lines] = { kind = "vulnerable", pkg = pkg }
      if not first_pkg_line then first_pkg_line = #lines end
    end

    table.insert(lines, "")
  end

  -- Outdated section
  if #outdated > 0 then
    local name_width = #"Package"
    for _, pkg in ipairs(outdated) do
      if #pkg.name > name_width then name_width = #pkg.name end
    end
    name_width = name_width + 2

    table.insert(lines, "  Outdated Packages")
    table.insert(lines, "")
    local hdr_fmt = "  %-" .. name_width .. "s %-10s    %-10s"
    table.insert(lines, string.format(hdr_fmt, "Package", "Current", "Latest"))
    table.insert(lines, "  " .. string.rep("─", name_width + 28))

    local fmt = "  %-" .. name_width .. "s %-10s  → %-10s"
    for _, pkg in ipairs(outdated) do
      local line = string.format(fmt, pkg.name, pkg.current, pkg.latest)
      table.insert(lines, line)
      pkg_map[#lines] = { kind = "outdated", pkg = pkg }
      if not first_pkg_line then first_pkg_line = #lines end
    end

    table.insert(lines, "")
  end

  table.insert(lines, "  u upgrade │ U upgrade all │ i info │ r retry │ q close")

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Highlights
  for i, line in ipairs(lines) do
    local ln = i - 1
    if line:match("⚠ Vulnerable") then
      vim.api.nvim_buf_add_highlight(buf, ns, "DiagnosticError", ln, 0, -1)
    elseif line:match("Outdated Packages") then
      vim.api.nvim_buf_add_highlight(buf, ns, "Title", ln, 0, -1)
    elseif line:match("^  ─") or line:match("^  Package") or i == #lines then
      vim.api.nvim_buf_add_highlight(buf, ns, "Comment", ln, 0, -1)
    elseif pkg_map[i] then
      local entry = pkg_map[i]
      if entry.kind == "vulnerable" then
        local pkg = entry.pkg
        local sev_start, sev_end = line:find(pkg.severity, 1, true)
        if sev_start then
          local hl = pkg.severity == "Critical" and "DiagnosticError" or "DiagnosticWarn"
          vim.api.nvim_buf_add_highlight(buf, ns, hl, ln, sev_start - 1, sev_end)
        end
      else
        local pkg = entry.pkg
        local cur_start, cur_end = line:find(pkg.current, 1, true)
        if cur_start then
          vim.api.nvim_buf_add_highlight(buf, ns, "DiagnosticWarn", ln, cur_start - 1, cur_end)
        end
        local arrow_start, arrow_end = line:find("→", 1, true)
        if arrow_start then
          vim.api.nvim_buf_add_highlight(buf, ns, "Comment", ln, arrow_start - 1, arrow_end)
        end
        local latest_start, latest_end = line:find(pkg.latest, (cur_end or 0) + 1, true)
        if latest_start then
          vim.api.nvim_buf_add_highlight(buf, ns, "DiagnosticOk", ln, latest_start - 1, latest_end)
        end
      end
    end
  end

  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"

  local width = 0
  for _, line in ipairs(lines) do
    local w = vim.fn.strdisplaywidth(line)
    if w > width then width = w end
  end
  width = width + 2
  local height = #lines
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
  })

  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true

  if first_pkg_line then
    vim.api.nvim_win_set_cursor(win, { first_pkg_line, 0 })
  end

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local failed_map = {}

  local function set_line(line_nr, text, hl)
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, line_nr - 1, line_nr, false, { text })
    vim.api.nvim_buf_add_highlight(buf, ns, hl, line_nr - 1, 0, -1)
    vim.bo[buf].modifiable = false
  end

  local function mark_installing(line_nr, pkg)
    set_line(line_nr, string.format("  %-40s ⟳ installing...", pkg.name), "DiagnosticInfo")
    pkg_map[line_nr] = nil
  end

  local function mark_installed(line_nr, pkg)
    set_line(line_nr, string.format("  %-40s ✓ installed", pkg.name), "DiagnosticOk")
    failed_map[line_nr] = nil
  end

  local function mark_failed(line_nr, pkg)
    set_line(line_nr, string.format("  %-40s ✗ failed (r to retry)", pkg.name), "DiagnosticError")
    failed_map[line_nr] = pkg
  end

  local function run_upgrade(line_nr, pkg, on_done)
    mark_installing(line_nr, pkg)

    local csprojs = find_csprojs_for_package(pkg.name)
    local commands = {}
    if #csprojs == 0 then
      table.insert(commands, "dotnet add package " .. pkg.name)
    else
      for _, proj in ipairs(csprojs) do
        table.insert(commands, "dotnet add " .. vim.fn.shellescape(proj) .. " package " .. pkg.name)
      end
    end

    local i = 0
    local any_failed = false
    local function next_one()
      i = i + 1
      if i > #commands then
        if any_failed then
          mark_failed(line_nr, pkg)
        else
          mark_installed(line_nr, pkg)
        end
        if on_done then on_done() end
        return
      end
      vim.fn.jobstart(commands[i], {
        on_exit = function(_, code)
          vim.schedule(function()
            if code ~= 0 then any_failed = true end
            next_one()
          end)
        end,
      })
    end
    next_one()
  end

  local function upgrade_package()
    local line_nr = vim.api.nvim_win_get_cursor(win)[1]
    local entry = pkg_map[line_nr]
    if not entry then return end
    run_upgrade(line_nr, entry.pkg)
  end

  local function show_info()
    local line_nr = vim.api.nvim_win_get_cursor(win)[1]
    local entry = pkg_map[line_nr]
    if not entry then return end
    open_info_window(entry.pkg, entry.kind)
  end

  local function retry_package()
    local line_nr = vim.api.nvim_win_get_cursor(win)[1]
    local pkg = failed_map[line_nr]
    if not pkg then return end
    run_upgrade(line_nr, pkg)
  end

  local function upgrade_all()
    local queue = {}
    for line_nr, entry in pairs(pkg_map) do
      table.insert(queue, { line_nr = line_nr, pkg = entry.pkg })
    end
    if #queue == 0 then return end

    for _, e in ipairs(queue) do
      mark_installing(e.line_nr, e.pkg)
    end

    local i = 0
    local function next_upgrade()
      i = i + 1
      if i > #queue then return end
      local e = queue[i]
      run_upgrade(e.line_nr, e.pkg, next_upgrade)
    end
    next_upgrade()
  end

  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "q", close, opts)
  vim.keymap.set("n", "<Esc>", close, opts)
  vim.keymap.set("n", "u", upgrade_package, opts)
  vim.keymap.set("n", "<CR>", upgrade_package, opts)
  vim.keymap.set("n", "i", show_info, opts)
  vim.keymap.set("n", "r", retry_package, opts)
  vim.keymap.set("n", "U", upgrade_all, opts)
end

local function parse_vulnerable(data)
  local packages = {}
  local seen = {}
  if not data then return packages end
  for _, line in ipairs(data) do
    if line:match(">") then
      local name, resolved, severity, advisory = line:match("> (%S+)%s+(%S+)%s+(%S+)%s+(%S+)")
      if name then
        local key = name .. "|" .. resolved
        if not seen[key] then
          seen[key] = true
          table.insert(packages, { name = name, resolved = resolved, severity = severity, advisory = advisory })
        end
      end
    end
  end
  return packages
end

local function parse_outdated(data)
  local packages = {}
  local seen = {}
  if not data then return packages end
  for _, line in ipairs(data) do
    if line:match(">") then
      local name, _, current, latest = line:match("> (%S+)%s+(%S+)%s+(%S+)%s+(%S+)")
      if name then
        local key = name .. "|" .. current .. "|" .. latest
        if not seen[key] then
          seen[key] = true
          table.insert(packages, { name = name, current = current, latest = latest })
        end
      end
    end
  end
  return packages
end

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local has_project = vim.fn.glob("*.csproj") ~= ""
      or vim.fn.glob("*.sln") ~= ""
      or vim.fn.glob("*.slnx") ~= ""
    if not has_project then return end

    vim.notify("Checking NuGet packages...", vim.log.levels.INFO)

    local vulnerable = {}
    local outdated = {}
    local done_count = 0

    local function on_done()
      done_count = done_count + 1
      if done_count < 2 then return end

      vim.schedule(function()
        if #vulnerable > 0 or #outdated > 0 then
          open_nuget_popup(vulnerable, outdated)
        else
          vim.notify("All NuGet packages are up to date and secure", vim.log.levels.INFO)
        end
      end)
    end

    vim.fn.jobstart("dotnet list package --vulnerable --include-transitive", {
      stdout_buffered = true,
      on_stdout = function(_, data)
        vulnerable = parse_vulnerable(data)
      end,
      on_exit = function(_, code)
        if code ~= 0 then
          vim.schedule(function()
            vim.notify("Vulnerability check failed", vim.log.levels.WARN)
          end)
        end
        on_done()
      end,
    })

    vim.fn.jobstart("dotnet list package --outdated", {
      stdout_buffered = true,
      on_stdout = function(_, data)
        outdated = parse_outdated(data)
      end,
      on_exit = function(_, code)
        if code ~= 0 then
          vim.schedule(function()
            vim.notify("Outdated check failed", vim.log.levels.WARN)
          end)
        end
        on_done()
      end,
    })
  end,
})
