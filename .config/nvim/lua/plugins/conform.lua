return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = {
      -- NvChad base config: formatters_by_ft = { lua = { "stylua" } }
      -- Extended with user formatters
      formatters_by_ft = {
        lua = { "stylua" },
        csharp = { "csharpier" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        svelte = { "prettier" },
        vue = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        less = { "prettier" },
        scss = { "prettier" },
        markdown = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
      },
      format_after_save = function(bufnr)
        -- Disable autoformat for cshtml files
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        if bufname:match("%.cshtml$") then
          return
        end
        -- Return format options for other files
        return {
          timeout_ms = 500,
          lsp_fallback = true,
        }
      end,
    },
  },
}
