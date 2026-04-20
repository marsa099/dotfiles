# Neovim and its runtime dependencies (LSPs, formatters, tools).

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    neovim
    tree-sitter # nvim-treesitter uses this CLI to download and build parsers
    gcc # C compiler needed by tree-sitter to compile parsers
    nodejs # needed by typescript-language-server runtime
    nodePackages.typescript-language-server
    lua-language-server # Lua LSP (Mason binary broken on NixOS due to dynamic linking)
    stylua # Lua formatter (Mason binary broken on NixOS due to dynamic linking)
    nil # Nix LSP
    nixfmt # formatter used by nil (Nix LSP)
    fd # fast file finder used by telescope.nvim
    ripgrep # needed by telescope.nvim live_grep
    unzip # needed by mason to extract packages
    fzf # fuzzy finder used by nvim-bqf quickfix filtering
    # roslyn-ls provided by modules/roslyn-ls.nix (wrapped for correct DOTNET_ROOT)
  ];
}
