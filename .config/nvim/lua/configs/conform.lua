local options = {
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

  format_after_save = {
    -- These options will be passed to conform.format()
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

return options
