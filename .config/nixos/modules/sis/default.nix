# SIS work environment — everything needed for the day job, grouped here so it
# is obvious what is work-related and what is personal. Only this file is
# imported from configuration.nix; the submodules below come along with it.
{ lib, pkgs, ... }:

let
  # Local subnets stay out of Git; missing settings must fail the build.
  renderRoutes = import ./vpn-routes.nix { inherit lib; };
  routeCommands = renderRoutes {
    routes = import ./routes.local.nix;
    ip = "${pkgs.iproute2}/bin/ip";
  };
in
{
  imports = [
    ./azure-cli.nix
    ./bicep.nix
    ./azure-data-studio.nix
    ./dotnet.nix
    ./roslyn-ls.nix
    ./teams-fork.nix
    ./split-dns.nix
  ];

  # Private mappings stay outside Git. See README.md: use a path: flake so
  # hosts.local.nix is included. Fail rather than silently drop local routes.
  networking.hosts = import ./hosts.local.nix;

  # Keep the VPN address outside Git too. This file enters the Nix store:
  # only connection settings belong here, never passwords or tokens.
  environment.etc."openfortivpn/config" = {
    source = pkgs.writeText "sis-openfortivpn.conf" (
      (import ./vpn-config.nix { inherit lib; }) (builtins.readFile ./vpn.local.conf)
    );
    mode = "0600";
  };

  environment.systemPackages = with pkgs; [
    openfortivpn
  ];

  # vpn.local.conf must set set-routes = 0 and pppd-ipparam = sis.
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
      ${routeCommands}
    '';
  };
}
