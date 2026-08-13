# Mobile web interface for Pi. The npm package is installed in
# ~/.npm-global because pi-crust is not packaged in nixpkgs.
#
# Keep the API on loopback: Tailscale Serve provides the private HTTPS entry
# point, so pi-crust is never exposed directly on the LAN or public internet.
{ pkgs, ... }:

{
  systemd.user.services.pi-crust = {
    description = "pi-crust mobile interface for Pi";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "default.target" ];
    path = [ pkgs.nodejs_latest ];

    environment = {
      PI_CRUST_API_HOST = "127.0.0.1";
      PI_CRUST_OPEN = "0";
      PI_CRUST_PI_COMMAND = "/home/martin/.npm-global/bin/pi";
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
