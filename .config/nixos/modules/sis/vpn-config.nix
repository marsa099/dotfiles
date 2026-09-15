# Preserve connection settings, but let local dnsmasq own all DNS routing.
# Strip existing directives so duplicate-key/first-key parser behavior cannot
# re-enable direct resolv.conf writes or PPP-installed global resolvers.
{ lib }:
text:
let
  retained = builtins.filter (
    line: builtins.match "[[:space:]]*(set-dns|pppd-use-peerdns)[[:space:]]*=.*" line == null
  ) (lib.splitString "\n" text);
in
lib.concatStringsSep "\n" retained
+ ''

  # Managed by NixOS: domain-specific DNS is handled by local dnsmasq.
  set-dns = 0
  pppd-use-peerdns = 0
''
