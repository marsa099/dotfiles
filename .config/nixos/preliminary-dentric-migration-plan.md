# Preliminary Dendritic Migration Plan

> **NOTE:** This is NOT a committed plan. It's a rough sketch of what a modular
> NixOS restructure could look like. We may or may not do this - it's here for
> reference if we decide to migrate later.

## Context

Current NixOS config is a working single-machine setup: `flake.nix` -> `configuration.nix` (226-line monolith) + 3 extracted modules (dotnet, neovim, roslyn-ls). No home-manager. Goal: modularity, multi-host support (hypothetical for now), pluggable modules - while keeping existing dotfiles (tmux, nvim, waybar, niri, ghostty configs) **outside** Nix so the dotfile repo stays portable to Arch.

## Recommendation: Simple Modular (NOT full dendritic)

The full dendritic pattern (flake-parts, import-tree, string-based module resolution) adds indirection for zero current benefit with 1 machine. Start simple; the module files stay the same if you upgrade to dendritic later.

Reference repos studied: jlodenius/.nixos (flake-parts + import-tree, single host), fbosch/nixos (full dendritic with presets), mightyiam/dendritic (pattern docs).

## Proposed Structure

```
flake.nix                              # Add home-manager input, reference hosts/
hosts/
  nixos/                               # Current machine (keep hostname as-is)
    default.nix                        # Imports exactly which modules this host needs
    hardware-configuration.nix         # Moved here (machine-specific)
modules/
  system/
    boot.nix                           # systemd-boot, EFI
    networking.nix                     # networkmanager
    locale.nix                         # timezone, i18n, GTK_IM_MODULE
    nix.nix                            # experimental features, allowUnfree, nix-ld
    users.nix                          # user martin, groups
  desktop/
    niri.nix                           # niri, greetd, xdg portal, xwayland-satellite
    waybar.nix                         # waybar + upower
    audio.nix                          # pipewire
    bluetooth.nix                      # bluetooth + blueman
    notifications.nix                  # dunst + libnotify + wtype
    fonts.nix                          # all font packages
    swaylock.nix                       # swaylock-effects + PAM
    kanshi.nix                         # dynamic monitor config
    keyboard.nix                       # xkb layout + us_swedish file
    appearance.nix                     # swaybg, glib/gsettings, fuzzel
  development/
    dotnet.nix                         # existing (move from modules/)
    neovim.nix                         # existing (move from modules/)
    roslyn-ls.nix                      # existing (move from modules/)
    docker.nix                         # virtualisation.docker
  programs/
    browsers.nix                       # firefox, zen-browser, google-chrome
    communication.nix                  # discord, vesktop, teams, thunderbird
    cli-tools.nix                      # git, gh, wget, jq, zoxide, bat, tv, cloc, python3, wev
    cloud.nix                          # azure-cli, terraform, sqlcmd
    terminal.nix                       # ghostty, tmux, vim (packages only)
    media.nix                          # spotify-player
    security.nix                       # pass, gnupg agent with SSH
  home/
    default.nix                        # minimal home-manager config
us_swedish                             # xkb layout file (referenced by keyboard.nix)
```

## How It Works

### Home Manager Integration
- Added as a **NixOS module** (not standalone) - single `nixos-rebuild switch`
- `home-manager.useGlobalPkgs = true` / `useUserPackages = true`
- Minimal usage: user session env, XDG dirs. Does NOT manage config files.
- Future: can use `home.file` to symlink to dotfile repo paths if desired

### Per-Host Module Selection
Each `hosts/<name>/default.nix` explicitly imports what it needs:

```nix
# hosts/nixos/default.nix
{ ... }: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/system/boot.nix
    ../../modules/system/networking.nix
    ../../modules/system/locale.nix
    ../../modules/system/nix.nix
    ../../modules/system/users.nix
    ../../modules/desktop/niri.nix
    ../../modules/desktop/waybar.nix       # remove for a headless host
    ../../modules/desktop/audio.nix
    # ... etc
    ../../modules/programs/terminal.nix
    ../../modules/home/default.nix
  ];
  networking.hostName = "nixos";
  system.stateVersion = "25.11";
}
```

Adding a second computer = add `hosts/secondpc/` with its own hardware-configuration.nix and import list + new entry in flake.nix `nixosConfigurations`.

### Dotfiles Strategy
Nix installs packages. Dotfile repo configures them. No `programs.tmux.extraConfig`, no `home.file."tmux.conf"`. Your `~/.config/tmux/tmux.conf` stays where it is, managed by your dotfile repo.

### flake.nix Changes

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  home-manager = {
    url = "github:nix-community/home-manager/release-25.11";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # ... existing: claude-code, zen-browser, claude-code-notify
};

outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }@inputs:
let
  system = "x86_64-linux";
  unstable = import nixpkgs-unstable { inherit system; config.allowUnfree = true; };
in {
  nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit unstable inputs; };
    modules = [
      ./hosts/nixos/default.nix
      { environment.systemPackages = [ /* flake packages */ ]; }
    ];
  };
};
```

## Migration Steps

Each step ends with `sudo nixos-rebuild switch --flake .#nixos` to verify:

1. Add home-manager input to flake.nix, run `nix flake update`
2. Create directory structure (`hosts/nixos/`, `modules/{system,desktop,development,programs,home}/`)
3. Move hardware-configuration.nix to `hosts/nixos/`
4. Create `hosts/nixos/default.nix` that initially just imports `../../configuration.nix` (transitional step)
5. Update flake.nix to point at `./hosts/nixos/default.nix` instead of `./configuration.nix`
6. Extract system modules from configuration.nix: boot, networking, locale, nix, users
7. Extract desktop modules: niri, waybar, audio, bluetooth, notifications, fonts, swaylock, kanshi, keyboard, appearance
8. Extract program modules: browsers, communication, cli-tools, cloud, terminal, media, security
9. Move existing modules from `modules/` to `modules/development/` (dotnet, neovim, roslyn-ls) + add docker.nix
10. Add home-manager module (`modules/home/default.nix`)
11. Delete configuration.nix once fully extracted
12. Clean up old empty `modules/` files

## Verification

- After each extraction step: `sudo nixos-rebuild switch --flake .#nixos`
- Final: reboot, verify greetd -> niri starts, waybar renders, all apps launch
- Verify dotfile configs still work (tmux, nvim, waybar, ghostty, niri)
- Run `nix flake check` for any evaluation errors
