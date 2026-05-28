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
    teams-for-linux-fork = {
      url = "github:marsa099/teams-for-linux/main";
      flake = false;
    };
    # Upstream endcord source, pinned to the same rev daphen builds against so
    # his patches (modules/endcord-patches/) apply cleanly. Bump with care:
    # newer revs may break the patches.
    endcord-src = {
      url = "github:sparklost/endcord/b4f890b9b6f9e2a3b3494c41e78ad77f72859d4b";
      flake = false;
    };
    bt-keyboard-bridge.url = "path:/home/martin/repos/bt-keyboard-bridge";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      zen-browser,
      claude-code-notify,
      teams-for-linux-fork,
      endcord-src,
      bt-keyboard-bridge,
      ...
    }:
    let
      system = "x86_64-linux";
      unstable = import nixpkgs-unstable { inherit system; config.allowUnfree = true; };
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit unstable teams-for-linux-fork endcord-src; };
        modules = [
          ./configuration.nix
          bt-keyboard-bridge.nixosModules.default
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
