# nix eval --impure --json --expr 'let f = builtins.getFlake "path:/path/to/nixos";
# in import /path/to/nixos/modules/sis/vpn-config-tests.nix { lib = f.inputs.nixpkgs.lib; }'
{ lib }:
let
  render = import ./vpn-config.nix { inherit lib; };
  input = ''
    host = vpn.example.invalid
    set-routes = 0
    pppd-ipparam = sis
    set-dns = 1
      pppd-use-peerdns = 1
    set-dns=1
    # keep this comment
  '';
  result = render input;
  lines = lib.splitString "\n" result;
  count =
    pattern: builtins.length (builtins.filter (line: builtins.match pattern line != null) lines);
in
assert lib.hasInfix "host = vpn.example.invalid" result;
assert lib.hasInfix "set-routes = 0" result;
assert lib.hasInfix "pppd-ipparam = sis" result;
assert lib.hasInfix "# keep this comment" result;
assert !(lib.hasInfix "set-dns = 1" result);
assert !(lib.hasInfix "set-dns=1" result);
assert !(lib.hasInfix "pppd-use-peerdns = 1" result);
assert count "[[:space:]]*set-dns[[:space:]]*=.*" == 1;
assert count "[[:space:]]*pppd-use-peerdns[[:space:]]*=.*" == 1;
assert lib.hasInfix "set-dns = 0" (render "");
assert lib.hasInfix "pppd-use-peerdns = 0" (render "");
{
  retainedConnectionSettings = true;
  replacedDuplicateDnsDirectives = true;
  disabledBothDnsWriters = true;
  handlesEmptyInput = true;
}
