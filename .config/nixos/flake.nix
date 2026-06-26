{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Community flake for Zen Browser (most actively maintained)
    # See: https://wiki.nixos.org/wiki/Zen_Browser
    # Alternative (wiki-recommended): zen-browser = { url = "github:youwen5/zen-browser-flake"; inputs.nixpkgs.follows = "nixpkgs"; };
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    # Community flake for Helium browser (downloads upstream prebuilt release).
    # Not in nixpkgs. Update with: nix flake update helium-browser
    helium-browser = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    claude-code-notify.url = "github:marsa099/claude-code-notify";
    # Claude Code from a dedicated flake that repackages each upstream release
    # within hours, independent of nixpkgs-unstable. Update with just this input:
    #   nix flake update claude-code && sudo nixos-rebuild switch --flake .#nixos
    claude-code.url = "github:sadjow/claude-code-nix";
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
      helium-browser,
      claude-code-notify,
      claude-code,
      teams-for-linux-fork,
      endcord-src,
      bt-keyboard-bridge,
      ...
    }:
    let
      system = "x86_64-linux";
      unstable = import nixpkgs-unstable { inherit system; config.allowUnfree = true; };
      # Packages sourced from external flake inputs (not nixpkgs). Declared here
      # because flake inputs can only live in flake.nix; consumed in the same
      # systemPackages list as everything else via specialArgs.
      flakePackages = [
        claude-code.packages.${system}.default
        zen-browser.packages.${system}.default
        helium-browser.packages.${system}.default
        claude-code-notify.packages.${system}.default
      ];
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit unstable teams-for-linux-fork endcord-src flakePackages; };
        modules = [
          ./configuration.nix
          bt-keyboard-bridge.nixosModules.default
        ];
      };
    };
}
