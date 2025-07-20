return {
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "mason.nvim" },
    opts = {
      ensure_installed = { 
        "html", 
        "cssls", 
        "ts_ls", 
        "jsonls", 
        "tailwindcss",
        "bicep",
        "omnisharp"
        -- Note: all LSPs now managed by mason
      },
    },
  },
}