-- Handle automatic config reloading across all Neovim instances
local M = {}

-- Start server for this instance
function M.setup_server()
  -- Check if server already running
  if vim.v.servername ~= "" then
    return -- Server already started, don't create a new one
  end

  -- Generate consistent server name based on PID only
  local servername = string.format("/tmp/nvim-%s.sock", vim.fn.getpid())

  -- Start server
  if vim.fn.serverstart(servername) == 1 then
    -- Clean up socket when Neovim exits
    vim.api.nvim_create_autocmd("VimLeavePre", {
      once = true,
      callback = function()
        pcall(vim.fn.delete, servername)
      end,
    })

    -- Show status (optional)
    vim.defer_fn(function()
      local servers = vim.fn.serverlist()
      vim.notify(string.format("✓ Neovim server started (%d total active)", #servers), vim.log.levels.INFO)
    end, 100)
  end
end

-- Send command to all other instances
function M.broadcast_reload()
  local servers = vim.fn.serverlist()
  local current = vim.v.servername
  local reloaded = 0
  local failed = 0
  
  for _, server in ipairs(servers) do
    if server ~= current then
      -- Try to send reload command
      local ok = pcall(function()
        vim.fn.remote_send(server, '<Esc>:lua require("utils.reload").reload_config()<CR>')
      end)
      
      if ok then
        reloaded = reloaded + 1
      else
        failed = failed + 1
        -- Remove dead socket
        pcall(vim.fn.delete, server)
      end
    end
  end
  
  return reloaded, failed
end

-- Reload config (called both locally and remotely)
function M.reload_config()
  -- Clear Lua modules from cache (except plugins, lazy, and this reload script)
  for name, _ in pairs(package.loaded) do
    if not name:match("^plugins") and not name:match("^lazy") and name ~= "utils.reload" then
      package.loaded[name] = nil
    end
  end

  -- Reload only specific config modules (NOT init.lua to avoid re-initializing lazy.nvim)
  local ok, err = pcall(function()
    -- Reload config modules
    require("config.options")

    -- Add other config modules as you create them
    -- local modules_to_reload = {"config.keymaps", "config.autocmds"}
    -- for _, module in ipairs(modules_to_reload) do
    --   if package.loaded[module] then
    --     require(module)
    --   end
    -- end
  end)

  if not ok then
    -- Show detailed error
    vim.notify("✗ Reload failed: " .. tostring(err), vim.log.levels.ERROR)

    -- Also print to messages for full stacktrace
    print("Full error details:")
    print(debug.traceback(err))
  end

  return ok
end

-- Setup autocmd for automatic reloading
function M.setup_autocmd()
  local group = vim.api.nvim_create_augroup("ConfigReload", { clear = true })
  
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = vim.fn.stdpath("config") .. "/**/*.lua",
    callback = function(args)
      -- Show which file triggered the reload
      local file = vim.fn.fnamemodify(args.file, ":~:.")

      -- Reload locally
      local ok = M.reload_config()

      if ok then
        -- Broadcast to other instances
        local reloaded, failed = M.broadcast_reload()

        -- Combine all messages into one notification
        local msg = "✅ Config reloaded"
        if reloaded > 0 then
          msg = msg .. string.format(" | ✓ %d other instance(s)", reloaded)
        end
        if failed > 0 then
          msg = msg .. string.format(" | ⚠ %d unreachable", failed)
        end

        -- Single notification with appropriate level
        local level = failed > 0 and vim.log.levels.WARN or vim.log.levels.INFO
        vim.notify(msg, level)
      end
    end,
  })
end

-- Initialize everything
function M.setup()
  M.setup_server()
  M.setup_autocmd()
end

return M
