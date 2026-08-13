# Native mobile interface for coding agents, including Pi. The CLI is installed
# in ~/.npm-global because Paseo is not packaged in nixpkgs.
#
# Bind only to this machine's Tailscale address. The interface-specific firewall
# rule keeps port 6767 closed on LAN/public interfaces, while Paseo password
# authentication provides a second access-control layer inside the tailnet.
{ lib, pkgs, ... }:

let
  tailscaleAddress = "100.121.105.35";
  paseoPort = 6767;
  paseoPath = lib.makeBinPath [
    pkgs.bash
    pkgs.coreutils
    pkgs.findutils
    pkgs.git
    pkgs.gnugrep
    pkgs.gnused
    pkgs.nodejs_latest
    pkgs.openssh
  ];
  paseoDaemon = pkgs.writeShellScript "paseo-daemon" ''
    export PATH="/home/martin/.scripts:/home/martin/.npm-global/bin:/home/martin/.local/bin:/etc/profiles/per-user/martin/bin:/run/current-system/sw/bin:${paseoPath}"
    exec /home/martin/.npm-global/bin/paseo daemon start \
      --foreground \
      --listen ${tailscaleAddress}:${toString paseoPort} \
      --hostnames ${tailscaleAddress} \
      --no-relay \
      --no-web-ui
  '';
in
{
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ paseoPort ];

  systemd.user.services.paseo = {
    description = "Paseo mobile interface for coding agents";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "default.target" ];

    environment = {
      HOME = "/home/martin";
      PASEO_HOME = "/home/martin/.paseo";
    };

    serviceConfig = {
      Type = "simple";
      ExecStart = paseoDaemon;
      WorkingDirectory = "/home/martin";
      Restart = "on-failure";
      RestartSec = "3s";
      UMask = "0077";
    };
  };
}
