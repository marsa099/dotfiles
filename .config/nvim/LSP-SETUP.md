# LSP Server Setup

## Current Setup (NixOS)

LSP servers and formatters are installed via **nixpkgs** in `configuration.nix`.
Mason is only used for **bicep-lsp** (not available in nixpkgs, runs as a .NET DLL via `dotnet`).

### Installed via nixpkgs

| Tool | Nix Package | Purpose |
|------|-------------|---------|
| lua-language-server | `lua-language-server` | Lua LSP |
| stylua | `stylua` | Lua formatter |
| nixd | `nixd` | Nix LSP (evaluates the flake for NixOS options completion) |
| roslyn-ls | `roslyn-ls` | C# LSP (Roslyn) |
| typescript-language-server | `nodePackages.typescript-language-server` | TypeScript/JS LSP |
| nixfmt | `nixfmt` | Nix formatter (used by nixd) |

### Installed via Mason

| Tool | Reason |
|------|--------|
| bicep-lsp | Not in nixpkgs. .NET DLL downloaded by Mason, run via `dotnet`. |

### Why not Mason for everything?

Mason downloads pre-built binaries for generic Linux. On NixOS these often fail
because NixOS doesn't have a standard filesystem layout (no `/lib/ld-linux-x86-64.so.2`).
Tools that are .NET DLLs or Node-based work fine via Mason since they run through
`dotnet`/`node` interpreters rather than being native binaries.

## Moving to a non-NixOS distro

If switching away from NixOS, you can go back to Mason for everything:

1. Remove the LSP packages from your system package manager
2. Update `plugins/mason.lua` ensure_installed list to include all tools:
   ```lua
   ensure_installed = {
       "lua-language-server",
       "stylua",
       "nixd",
       "typescript-language-server",
       "bicep-lsp",
   }
   ```
3. Roslyn is handled separately by `roslyn.nvim` plugin (check its docs for install)
4. The `vim.lsp.config()` and `vim.lsp.enable()` calls in `lsp.lua` work
   regardless of how the binaries are installed - they just need to be in PATH
