# Render validated IPv4 routes for the PPP hook without exposing local subnets in Git.
{ lib }:
{ routes, ip }:
let
  octet = "([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])";
  cidr = "${octet}\\.${octet}\\.${octet}\\.${octet}/([0-9]|[12][0-9]|3[0-2])";
  valid =
    builtins.isList routes
    && routes != [ ]
    && builtins.all (route: builtins.isString route && builtins.match cidr route != null) routes;
in
assert lib.assertMsg valid "SIS routes.local.nix must be a non-empty list of IPv4 CIDR strings.";
lib.concatStringsSep "\n" (
  lib.imap0 (
    index: route:
    "${
      lib.optionalString (index == builtins.length routes - 1) "exec "
    }${lib.escapeShellArg ip} route add ${lib.escapeShellArg route} dev \"$1\""
  ) routes
)
