# Private remote access for Pi Remote and other local services.
#
# Tailscale remains disconnected until `tailscale up` completes the one-time
# browser login. The operator setting lets martin manage this node and Tailscale
# Serve without sudo after the NixOS service starts.
{ ... }:

{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    # DNS is routed locally by domain, not installed as a global nameserver.
    extraSetFlags = [
      "--operator=martin"
      "--accept-dns=false"
    ];
  };

  # Keep normal NetworkManager upstreams via openresolv. SIS adds corporate
  # suffix rules without installing VPN DNS globally; ts.net uses MagicDNS.
  # Never expose a DNS listener to the LAN or tailnet.
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    settings = {
      listen-address = [
        "127.0.0.1"
        "::1"
      ];
      bind-interfaces = true;
      strict-order = true;
      server = [ "/ts.net/100.100.100.100" ];
    };
  };
}
