# Private remote access for Paseo and other local services.
#
# Tailscale remains disconnected until `tailscale up` completes the one-time
# browser login. The operator setting lets martin manage this node and Tailscale
# Serve without sudo after the NixOS service starts.
{ ... }:

{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    extraSetFlags = [ "--operator=martin" ];
  };
}
