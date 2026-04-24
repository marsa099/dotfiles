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

  table.insert(lines, "  u upgrade │ U upgrade all │ q close")

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

  local width = 90
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

  local function mark_upgraded(line_nr, pkg)
    vim.bo[buf].modifiable = true
    local updated = string.format("  %-40s ✓ upgraded", pkg.name)
    vim.api.nvim_buf_set_lines(buf, line_nr - 1, line_nr, false, { updated })
    vim.api.nvim_buf_add_highlight(buf, ns, "DiagnosticOk", line_nr - 1, 0, -1)
    vim.bo[buf].modifiable = false
    pkg_map[line_nr] = nil
  end

  local function upgrade_package()
    local line_nr = vim.api.nvim_win_get_cursor(win)[1]
    local entry = pkg_map[line_nr]
    if not entry then return end
    local pkg = entry.pkg

    vim.notify("Upgrading " .. pkg.name .. "...", vim.log.levels.INFO)
    vim.fn.jobstart("dotnet add package " .. pkg.name, {
      on_exit = function(_, code)
        vim.schedule(function()
          if code == 0 then
            mark_upgraded(line_nr, pkg)
            vim.notify(pkg.name .. " upgraded", vim.log.levels.INFO)
          else
            vim.notify("Failed to upgrade " .. pkg.name, vim.log.levels.ERROR)
          end
        end)
      end,
    })
  end

  local function upgrade_all()
    local queue = {}
    for line_nr, entry in pairs(pkg_map) do
      table.insert(queue, { line_nr = line_nr, pkg = entry.pkg })
    end
    if #queue == 0 then return end

    local i = 0
    local function next_upgrade()
      i = i + 1
      if i > #queue then
        vim.schedule(function()
          vim.notify("All packages upgraded!", vim.log.levels.INFO)
        end)
        return
      end
      local e = queue[i]
      vim.schedule(function()
        vim.notify(
          string.format("Upgrading %s (%d/%d)...", e.pkg.name, i, #queue),
          vim.log.levels.INFO
        )
      end)
      vim.fn.jobstart("dotnet add package " .. e.pkg.name, {
        on_exit = function(_, code)
          vim.schedule(function()
            if code == 0 then
              mark_upgraded(e.line_nr, e.pkg)
            else
              vim.notify("Failed to upgrade " .. e.pkg.name, vim.log.levels.ERROR)
            end
          end)
          next_upgrade()
        end,
      })
    end
    next_upgrade()
  end

  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "q", close, opts)
  vim.keymap.set("n", "<Esc>", close, opts)
  vim.keymap.set("n", "u", upgrade_package, opts)
  vim.keymap.set("n", "<CR>", upgrade_package, opts)
  vim.keymap.set("n", "U", upgrade_all, opts)
end

local function parse_vulnerable(data)
  local packages = {}
  if not data then return packages end
  for _, line in ipairs(data) do
    if line:match(">") then
      local name, resolved, severity, advisory = line:match("> (%S+)%s+(%S+)%s+(%S+)%s+(%S+)")
      if name then
        table.insert(packages, { name = name, resolved = resolved, severity = severity, advisory = advisory })
      end
    end
  end
  return packages
end

local function parse_outdated(data)
  local packages = {}
  if not data then return packages end
  for _, line in ipairs(data) do
    if line:match(">") then
      local name, _, current, latest = line:match("> (%S+)%s+(%S+)%s+(%S+)%s+(%S+)")
      if name then
        table.insert(packages, { name = name, current = current, latest = latest })
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
