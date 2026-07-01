# Scoped auto-update for Claude Code.
#
# Bumps ONLY the `claude-code` flake input (github:sadjow/claude-code-nix) and
# rebuilds. Because Claude Code is its own input, this never moves any other
# package from nixpkgs-unstable — the only thing that changes on switch is the
# claude-code closure, so activation stays minimal.
#
# Trade-off to know about: each run rewrites flake.lock in ~/.config/nixos,
# which lives in the dotfiles repo. The change is left UNCOMMITTED on purpose
# (no unattended git history rewrites) — commit it yourself with `config` when
# convenient. Failures are non-fatal and land in `journalctl -u claude-code-update`.
{ config, pkgs, lib, ... }:

let
  flakeDir = "/home/martin/.config/nixos";
  updateScript = pkgs.writeShellScript "claude-code-update" ''
    set -euo pipefail
    cd ${flakeDir}
    # /home/martin is a git working tree (dotfiles bare repo); root touching it
    # trips git's ownership guard and aborts the flake update. Allow it.
    ${pkgs.git}/bin/git config --global --add safe.directory /home/martin
    ${pkgs.nix}/bin/nix flake update claude-code \
      --extra-experimental-features 'nix-command flakes'
    ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --flake ${flakeDir}#nixos
    # Root rewrote flake.lock; hand it back to martin so the dotfiles repo
    # doesn't accumulate root-owned files to chown before committing.
    ${pkgs.coreutils}/bin/chown martin:users ${flakeDir}/flake.lock
  '';
in
{
  systemd.services.claude-code-update = {
    description = "Update Claude Code flake input and rebuild";
    # git is only needed if nix ever shells out for the local flake; harmless to provide.
    path = [ pkgs.git pkgs.nix pkgs.nixos-rebuild ];
    environment.HOME = "/root";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = updateScript;
    };
  };

  systemd.timers.claude-code-update = {
    description = "Daily Claude Code update check";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;          # catch up if the machine was off at the scheduled time
      RandomizedDelaySec = "30min";
    };
  };
}
