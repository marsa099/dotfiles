# Pi Remote exposes semantic session events to a separately rendered mobile web
# interface. Pi itself stays in a laptop-sized tmux client; the phone never
# receives terminal bytes or influences PTY dimensions.
#
# The HTTP listener is bound to this machine's Tailscale address only. Tailscale
# encrypts transport, the interface-specific firewall keeps the port off LAN and
# public interfaces, and Pi Remote adds a persistent access token.
{ pkgs, ... }:

let
  tailscaleAddress = "100.121.105.35";
  piRemotePort = 6767;
in
{
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ piRemotePort ];

  environment.systemPackages = [ pkgs.qrencode ];

  environment.sessionVariables = {
    PI_REMOTE_HOST = tailscaleAddress;
    PI_REMOTE_PORT = toString piRemotePort;
  };
}
