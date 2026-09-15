# SIS work environment — everything needed for the day job, grouped here so it
# is obvious what is work-related and what is personal. Only this file is
# imported from configuration.nix; the submodules below come along with it.
{ pkgs, ... }:

{
  imports = [
    ./azure-cli.nix
    ./bicep.nix
    ./azure-data-studio.nix
    ./dotnet.nix
    ./roslyn-ls.nix
    ./teams-fork.nix
  ];

  # Local dev hostnames. SD-API binds to sd-api.dev.sis.se in its launch
  # settings so it can match the local cert SAN — route it to loopback.
  networking.hosts = {
    "127.0.0.1" = [ "sd-api.dev.sis.se" ];
  };

  environment.systemPackages = with pkgs; [
    openfortivpn
    remmina # Graphical RDP connection manager.
    freerdp # FreeRDP 3; Nixpkgs names its X11 client xfreerdp.
  ];

  # In /etc/openfortivpn/config, use:
  #   set-routes = 0
  #   pppd-ipparam = sis
  # pppd calls ip-up with: interface tty speed local-ip remote-ip ipparam.
  # Only this explicitly tagged connection gets the SIS production and test
  # routes. The kernel removes them when the PPP interface disappears.
  environment.etc."ppp/ip-up" = {
    mode = "0755";
    text = ''
      #!${pkgs.runtimeShell}
      set -e
      if [ "''${6-}" != "sis" ]; then
        exit 0
      fi
      if [ -z "''${1-}" ]; then
        exit 1
      fi
      ${pkgs.iproute2}/bin/ip route add 172.16.0.0/16 dev "$1"
      exec ${pkgs.iproute2}/bin/ip route add 10.10.20.0/24 dev "$1"
    '';
  };
}
