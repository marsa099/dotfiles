# Pure tests use documentation-only subnets, never private work-network values.
{ lib }:
let
  render = import ./vpn-routes.nix { inherit lib; };
  accepts =
    routes:
    (builtins.tryEval (render {
      inherit routes;
      ip = "/test/ip";
    })).success;
  checks = {
    preservesOrderAndFinalExec =
      render {
        routes = [
          "192.0.2.0/24"
          "198.51.100.0/24"
        ];
        ip = "/test/ip";
      }
      == "/test/ip route add 192.0.2.0/24 dev \"$1\"\nexec /test/ip route add 198.51.100.0/24 dev \"$1\"";
    singleRoute =
      render {
        routes = [ "203.0.113.0/24" ];
        ip = "/test/ip";
      } == "exec /test/ip route add 203.0.113.0/24 dev \"$1\"";
    acceptsBoundaryPrefixes = accepts [
      "0.0.0.0/0"
      "255.255.255.255/32"
    ];
    rejectsEmpty = !accepts [ ];
    rejectsWrongType = !accepts "192.0.2.0/24";
    rejectsNonString = !accepts [ 123 ];
    rejectsBadOctet = !accepts [ "999.0.2.0/24" ];
    rejectsBadPrefix = !accepts [ "192.0.2.0/33" ];
    rejectsMissingPrefix = !accepts [ "192.0.2.0" ];
    rejectsShellInjection = !accepts [ "192.0.2.0/24; echo unsafe" ];
  };
in
assert lib.assertMsg (builtins.all (value: value) (
  builtins.attrValues checks
)) "VPN route regression checks failed.";
checks
