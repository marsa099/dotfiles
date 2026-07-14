# Notify-only watcher for the Helium browser.
#
# Helium is an independently-pinned flake input (github:oxcl/nix-flake-helium-browser,
# a repackage of upstream imputnet/helium prebuilt releases). It updates on its own
# track: neither a nixos-26.05 channel bump nor a nixpkgs-unstable bump moves it —
# only `nix flake update helium-browser` does. Because the browser is the main
# remote-code-execution surface and Chromium ships frequent security fixes, silent
# drift here is a real risk (it lagged a full Chromium major once already, mid-2026).
#
# This is a NOTIFY-ONLY daily check: it compares the installed Helium version against
# the latest upstream release and, if behind, fires a desktop notification with the
# exact update command. It never changes the system itself — applying the update is
# always a deliberate manual step.
#
# To also cover the other self-pinned Electron/Chromium inputs (teams-for-linux fork,
# dsqrd, slqs), add analogous checks here — Helium is done first as the sharpest edge.
{ pkgs, ... }:
let
  check = pkgs.writeShellScript "helium-update-check" ''
    # Installed version, parsed from the store path (no need to launch the browser).
    installed=$(${pkgs.coreutils}/bin/readlink -f /run/current-system/sw/bin/helium 2>/dev/null \
      | ${pkgs.gnugrep}/bin/grep -oE 'helium-[0-9][0-9.]*' \
      | ${pkgs.gnused}/bin/sed 's/helium-//') || true
    [ -n "$installed" ] || exit 0

    # Latest upstream release tag (e.g. 0.14.5.1). Fail quiet if offline.
    latest=$(${pkgs.curl}/bin/curl -fsSL --max-time 20 \
      https://api.github.com/repos/imputnet/helium-linux/releases/latest 2>/dev/null \
      | ${pkgs.jq}/bin/jq -r '.tag_name' 2>/dev/null) || true
    [ -n "$latest" ] || exit 0
    [ "$installed" = "$latest" ] && exit 0

    # Only alert on a genuine upgrade (latest must sort newest under version sort).
    newest=$(printf '%s\n%s\n' "$installed" "$latest" \
      | ${pkgs.coreutils}/bin/sort -V | ${pkgs.coreutils}/bin/tail -1)
    [ "$newest" = "$latest" ] || exit 0

    ${pkgs.libnotify}/bin/notify-send -u critical -a "Security" \
      "Helium update available: $installed → $latest" \
      "Chromium security fixes pending. Run: nix flake update helium-browser && sudo nixos-rebuild switch --flake ~/.config/nixos#nixos"
  '';
in
{
  systemd.user.services.helium-update-check = {
    description = "Check for Helium browser (Chromium) security updates";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${check}";
    };
  };

  systemd.user.timers.helium-update-check = {
    description = "Daily Helium browser update check";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      # If the daily run was missed because the machine was off/suspended,
      # Persistent triggers it as soon as the user session comes back up on the
      # next power-on — the missed check is not skipped, just deferred to boot.
      Persistent = true;
      # Small delay only (not "as soon as" defeating): gives the session's
      # notification daemon (qs-picker NotifService) a moment to start after
      # login, so a catch-up notification on boot is actually delivered rather
      # than fired into a dead bus and dropped.
      RandomizedDelaySec = "2m";
    };
  };
}
