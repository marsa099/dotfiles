# Corporate domains and resolver addresses are local-only, just like hosts.
{ lib, pkgs, ... }:
let
  dns = import ./dns.local.nix;
  validDomain = domain: builtins.match "[a-zA-Z0-9-]+(\\.[a-zA-Z0-9-]+)*" domain != null;
in
{
  assertions = [
    {
      assertion = dns.servers != [ ] && dns.domains != [ ];
      message = "SIS dns.local.nix must provide non-empty servers and domains lists.";
    }
    {
      assertion =
        builtins.all validDomain dns.domains
        && builtins.all (domain: domain != "ts.net" && !(lib.hasSuffix ".ts.net" domain)) dns.domains;
      message = "SIS DNS domains must be literal DNS suffixes and must not override Tailscale's ts.net zone.";
    }
    {
      assertion = builtins.all (server: builtins.match "[0-9]+(\\.[0-9]+){3}" server != null) dns.servers;
      message = "SIS DNS servers must be IPv4 addresses, not URLs or domain-rule expressions.";
    }
  ];

  # These suffix rules are merged with tailscale.nix's /ts.net/MagicDNS rule.
  # Unmatched names retain the normal NetworkManager/openresolv upstreams.
  services.dnsmasq.settings.server = map (
    server: "/${lib.concatStringsSep "/" dns.domains}/${server}"
  ) dns.servers;

  # A currently running VPN may already have prepended its DNS servers directly
  # to resolv.conf. Rebuild the file from openresolv's registered inputs without
  # disconnecting PPP or changing routes. Future connections cannot prepend them
  # because the generated openfortivpn configuration disables both DNS writers.
  system.activationScripts.sisSplitDns = {
    deps = [ "etc" ];
    text = ''
      ${pkgs.openresolv}/bin/resolvconf -u
    '';
  };
}
