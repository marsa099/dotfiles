return {
  {
    "Hoffs/omnisharp-extended-lsp.nvim",
    lazy = true,
    ft = { "cs" },
    config = function()
      -- Set up keybindings only when plugin is loaded (for C# files)
      local map = vim.keymap.set
      
      map("n", "<leader>D", function()
        require("omnisharp_extended").telescope_lsp_references()
      end, { noremap = true, buffer = true, desc = "OmniSharp telescope references" })
      
      map("n", "gi", function()
        require("omnisharp_extended").telescope_lsp_implementation()
      end, { noremap = true, buffer = true, desc = "OmniSharp telescope implementation" })
      
      map("n", "gd", function()
        require("omnisharp_extended").lsp_definition()
      end, { noremap = true, buffer = true, desc = "OmniSharp enhanced definition" })
    end,
  },
}