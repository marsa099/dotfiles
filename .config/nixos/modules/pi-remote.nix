# Pi Remote source lives in the private ~/repos/pi-remote repository and is
# linked into Pi's extension and script paths by this dotfiles checkout. This
# host-specific module keeps the Tailscale address and firewall policy local.
# Pi itself stays in a laptop-sized tmux client; the phone never receives
# terminal bytes or influences PTY dimensions.
#
# The HTTP listener is bound to this machine's Tailscale address only. Tailscale
# encrypts transport, the interface-specific firewall keeps the port off LAN and
# public interfaces, and Pi Remote adds a persistent access token.
{ lib, pkgs, ... }:

let
  tailscaleAddress = "100.121.105.35";
  piRemotePort = 6767;
  piRemoteMaxSessions = 16;
  piRemoteHubPort = piRemotePort + piRemoteMaxSessions + 1;
in
{
  # Paseo owns 6767. Pi sessions use 6768–6783; the persistent hub owns 6784.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = lib.range piRemotePort piRemoteHubPort;

  environment.systemPackages = [ pkgs.qrencode ];

  systemd.services.pi-remote-hub = {
    description = "Persistent Pi Remote mobile session hub";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "tailscaled.service" ];
    wants = [ "network-online.target" ];
    environment = {
      HOME = "/home/martin";
      PI_REMOTE_HOST = tailscaleAddress;
      PI_REMOTE_PORT = toString piRemotePort;
      PI_REMOTE_HUB_PORT = toString piRemoteHubPort;
      PI_SHARED = "/home/martin/.scripts/pi-shared";
    };
    path = [ pkgs.nodejs pkgs.tmux ];
    serviceConfig = {
      Type = "simple";
      User = "martin";
      Group = "users";
      ExecStart = "${pkgs.nodejs}/bin/node /home/martin/repos/pi-remote/hub.cjs";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  environment.sessionVariables = {
    PI_REMOTE_HOST = tailscaleAddress;
    PI_REMOTE_PORT = toString piRemotePort;
    PI_REMOTE_HUB_PORT = toString piRemoteHubPort;
  };
}
