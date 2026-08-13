# Mobile web interface for Pi. The npm package is installed in
# ~/.npm-global because pi-crust is not packaged in nixpkgs.
#
# Keep the API on loopback: Tailscale Serve provides the private HTTPS entry
# point, so pi-crust is never exposed directly on the LAN or public internet.
{
  lib,
  pkgs,
  ...
}:

let
  piSessionRoot = "/home/martin/.pi/agent/sessions";
  piCrustSessionRoot = "/home/martin/.pi/agent/pi-crust-sessions";

  importPiSessions = pkgs.writeShellApplication {
    name = "pi-crust-import-sessions";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
    ];
    text = ''
      source_root=${lib.escapeShellArg piSessionRoot}
      target_root=${lib.escapeShellArg piCrustSessionRoot}

      install -d -m 0700 "$target_root"

      while IFS= read -r -d "" source_file; do
        target_file="$target_root/$(basename "$source_file")"

        if [ -e "$target_file" ]; then
          if [ "$source_file" -ef "$target_file" ]; then
            continue
          fi
          echo "Skipping session basename collision: $source_file -> $target_file" >&2
          continue
        fi

        # Hard links keep terminal Pi and pi-crust on the same JSONL inode,
        # without duplicating transcript data or modifying Pi's directory tree.
        ln "$source_file" "$target_file"
      done < <(find "$source_root" -mindepth 2 -type f -name '*.jsonl' -print0)
    '';
  };
in
{
  systemd.user.services.pi-crust-session-import = {
    description = "Expose existing Pi sessions to pi-crust";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe importPiSessions;
    };
  };

  systemd.user.timers.pi-crust-session-import = {
    description = "Import new terminal Pi sessions into pi-crust";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "15s";
      OnUnitActiveSec = "30s";
      Persistent = true;
      Unit = "pi-crust-session-import.service";
    };
  };

  systemd.user.services.pi-crust = {
    description = "pi-crust mobile interface for Pi";
    after = [
      "network-online.target"
      "pi-crust-session-import.service"
    ];
    wants = [ "network-online.target" ];
    requires = [ "pi-crust-session-import.service" ];
    wantedBy = [ "default.target" ];
    path = [ pkgs.nodejs_latest ];

    environment = {
      PI_CRUST_API_HOST = "127.0.0.1";
      PI_CRUST_OPEN = "0";
      PI_CRUST_PI_COMMAND = "/home/martin/.npm-global/bin/pi";
      PI_CRUST_SESSION_ROOT = piCrustSessionRoot;
    };

    serviceConfig = {
      Type = "simple";
      ExecStart = "/home/martin/.npm-global/bin/pi-crust-full";
      WorkingDirectory = "/home/martin";
      Restart = "on-failure";
      RestartSec = "3s";
    };
  };
}
