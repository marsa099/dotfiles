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

  # Private mappings stay outside Git. See README.md: use a path: flake so
  # hosts.local.nix is included. Fail rather than silently drop local routes.
  networking.hosts = import ./hosts.local.nix;

  environment.systemPackages = with pkgs; [
    openfortivpn
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
      ${pkgs.iproute2}/bin/ip route add 10.121.0.0/16 dev "$1"
      exec ${pkgs.iproute2}/bin/ip route add 10.10.20.0/24 dev "$1"
    '';
  };
}
