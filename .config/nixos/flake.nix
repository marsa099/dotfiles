{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    claude-code.url = "github:sadjow/claude-code-nix";
    # Community flake for Zen Browser (most actively maintained)
    # See: https://wiki.nixos.org/wiki/Zen_Browser
    # Alternative (wiki-recommended): zen-browser = { url = "github:youwen5/zen-browser-flake"; inputs.nixpkgs.follows = "nixpkgs"; };
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
  };

  outputs =
    {
      self,
      nixpkgs,
      claude-code,
      zen-browser,
      ...
    }:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          {
            environment.systemPackages = [
              claude-code.packages.x86_64-linux.default
              zen-browser.packages.x86_64-linux.default
            ];
          }
        ];
      };
    };
}
