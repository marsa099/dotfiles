{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Community flake for Zen Browser (most actively maintained)
    # See: https://wiki.nixos.org/wiki/Zen_Browser
    # Alternative (wiki-recommended): zen-browser = { url = "github:youwen5/zen-browser-flake"; inputs.nixpkgs.follows = "nixpkgs"; };
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    claude-code-notify.url = "github:marsa099/claude-code-notify";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      zen-browser,
      claude-code-notify,
      ...
    }:
    let
      system = "x86_64-linux";
      unstable = import nixpkgs-unstable { inherit system; config.allowUnfree = true; };
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit unstable; };
        modules = [
          ./configuration.nix
          {
            environment.systemPackages = [
              unstable.claude-code
              zen-browser.packages.${system}.default
              claude-code-notify.packages.${system}.default
            ];
          }
        ];
      };
    };
}
