# hemma — apartment dashboard (~/repos/hemma), run as a system service that is
# gated on being connected to a trusted WiFi. Off those networks the service
# refuses to start and TCP 7777 is closed in the firewall.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  allowedSsids = [
    "Alpaca Industries"
    "Galaxen"
    "dlink-5GHz-2B40"
  ];
  wifiIface = "wlp0s20f3";
  port = 7777;
  appDir = "/home/martin/repos/hemma";
  user = "martin";

  # Exit 0 iff the active WiFi connection is one of the trusted networks. Used
  # both as the service ExecCondition and by the firewall/dispatcher logic below.
  onHomeWifi = pkgs.writeShellScript "hemma-on-home-wifi" ''
    ${pkgs.networkmanager}/bin/nmcli -t -f active,ssid dev wifi 2>/dev/null \
      | ${pkgs.gnugrep}/bin/grep -qxF ${
        lib.concatMapStringsSep " " (s: ''-e "yes:${s}"'') allowedSsids
      }
  '';

  # Reacts to WiFi changes: re-evaluate the firewall (which re-checks the SSID
  # and opens/closes 7777) and start/stop hemma accordingly.
  dispatcher = pkgs.writeShellScript "hemma-netgate" ''
    case "$2" in
      up|down|connectivity-change|vpn-up|vpn-down) ;;
      *) exit 0 ;;
    esac
    ${pkgs.systemd}/bin/systemctl reload-or-restart firewall.service 2>/dev/null || true
    if ${onHomeWifi}; then
      ${pkgs.systemd}/bin/systemctl start hemma.service
    else
      ${pkgs.systemd}/bin/systemctl stop hemma.service
    fi
  '';
in
{
  # 7777 is intentionally NOT in networking.firewall.allowedTCPPorts — it is
  # closed by default and only opened here when on the home WiFi. extraCommands
  # runs on every firewall start/reload, so this re-evaluates on boot, on
  # nixos-rebuild switch, and whenever the dispatcher reloads the firewall.
  networking.firewall.extraCommands = ''
    if ${onHomeWifi}; then
      iptables -A nixos-fw -i ${wifiIface} -p tcp --dport ${toString port} -j nixos-fw-accept
    fi
  '';
  networking.firewall.extraStopCommands = ''
    iptables -D nixos-fw -i ${wifiIface} -p tcp --dport ${toString port} -j nixos-fw-accept 2>/dev/null || true
  '';

  networking.networkmanager.dispatcherScripts = [
    {
      source = dispatcher;
      type = "basic";
    }
  ];

  systemd.services.hemma = {
    description = "hemma — apartment dashboard";
    # wantedBy so a rebuild/boot starts it — ExecCondition still gates it to the
    # home WiFi, so off-network it is simply skipped (not failed).
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" "NetworkManager.service" ];
    # No start-rate limit: the hot-reload path unit restarts on every save, and
    # a crash-looping dashboard should keep retrying (RestartSec throttles it)
    # rather than lock itself out until the next WiFi change.
    unitConfig.StartLimitIntervalSec = 0;
    serviceConfig = {
      Type = "simple";
      User = user;
      Group = "users";
      WorkingDirectory = appDir;
      ExecCondition = "${onHomeWifi}";
      ExecStart = "${pkgs.python3}/bin/python3 ${appDir}/server.py";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  # Fail closed across suspend/resume. On wake, stop hemma and drop the port
  # rule immediately — before the WiFi reassociates — so the stale "open" state
  # from home never applies to a new, untrusted network. If we wake back on the
  # home WiFi the dispatcher re-opens it a moment later.
  systemd.services.hemma-resume-guard = {
    description = "Fail hemma closed on resume until home WiFi is reconfirmed";
    wantedBy = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
    after = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "hemma-resume-guard" ''
        ${pkgs.systemd}/bin/systemctl stop hemma.service 2>/dev/null || true
        while ${pkgs.iptables}/bin/iptables -C nixos-fw -i ${wifiIface} -p tcp --dport ${toString port} -j nixos-fw-accept 2>/dev/null; do
          ${pkgs.iptables}/bin/iptables -D nixos-fw -i ${wifiIface} -p tcp --dport ${toString port} -j nixos-fw-accept
        done
      '';
    };
  };

  # Hot reload: restart hemma when server.py changes. try-restart keeps it a
  # no-op while the service is stopped (i.e. off the home WiFi).
  systemd.paths.hemma-reload = {
    description = "Watch hemma server.py for changes (hot reload)";
    wantedBy = [ "multi-user.target" ];
    pathConfig.PathModified = "${appDir}/server.py";
  };
  systemd.services.hemma-reload = {
    description = "Restart hemma when server.py changes";
    # Plain restart (not try-restart) so a crashed/stopped hemma comes back on
    # the next code save too; ExecCondition still keeps it off untrusted WiFi.
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "hemma-reload" ''
        ${pkgs.systemd}/bin/systemctl reset-failed hemma.service 2>/dev/null || true
        ${pkgs.systemd}/bin/systemctl restart hemma.service
      '';
    };
  };
}
