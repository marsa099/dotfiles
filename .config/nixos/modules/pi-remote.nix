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
in
{
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = lib.range piRemotePort (piRemotePort + piRemoteMaxSessions - 1);

  environment.systemPackages = [ pkgs.qrencode ];

  environment.sessionVariables = {
    PI_REMOTE_HOST = tailscaleAddress;
    PI_REMOTE_PORT = toString piRemotePort;
  };
}
