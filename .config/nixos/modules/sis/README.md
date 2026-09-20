# SIS local network settings

`default.nix` imports `hosts.local.nix` as the `networking.hosts` attribute set.
The local file is gitignored. Do not force-add it. `hosts.example.nix` contains
only a placeholder and can be copied on a new machine:

```bash
cd ~/.config/nixos/modules/sis
cp -n hosts.example.nix hosts.local.nix
```

## Local VPN configuration

`default.nix` renders the gitignored `vpn.local.conf` into
`/etc/openfortivpn/config`, readable only by root (mode `0600`). It preserves
connection settings but removes any `set-dns` / `pppd-use-peerdns` directives
and appends both as `0`. This prevents the VPN from bypassing local split DNS. Keep the VPN
server address and non-secret connection settings in this local file. On a new
machine, copy `vpn.example.conf` to `vpn.local.conf` and replace its placeholder
host before rebuilding. Never force-add `vpn.local.conf` to Git.

The SIS route hook requires `set-routes = 0` and `pppd-ipparam = sis`. After the
first rebuild, edit `vpn.local.conf` and rebuild rather than manually editing
`/etc/openfortivpn/config`. The module does not start the VPN automatically.

**Gitignored is not secret storage.** Despite the installed file's `0600` mode,
the source configuration enters the world-readable Nix store. Never put
passwords, tokens, or private keys in it; keep authentication outside Nix inputs.

## Local VPN routes

`routes.local.nix` is a gitignored, non-empty list of IPv4 CIDR strings. Each
line can include a comment explaining the subnet. The PPP hook installs these
routes in list order, only for connections tagged `sis`, and the kernel removes
them when the PPP interface disappears. Moving the values here does not remove
previously committed values from Git history.

On a new machine, copy `routes.example.nix` to `routes.local.nix` and replace the
documentation-only subnet with the real work subnets before rebuilding. Missing,
empty, or malformed settings fail the build. Never force-add the local file.
These settings still enter the world-readable local Nix store; do not put
credentials in them.

## Build with the local files

Git flakes omit ignored files. Use the explicit **`path:`** flake form, which
includes all four local files (`hosts.local.nix`, `vpn.local.conf`,
`dns.local.nix`, and `routes.local.nix`), rather than the Git-inferred directory form:

```bash
sudo nixos-rebuild switch --flake "path:$HOME/.config/nixos#nixos"
```

Missing local files fail the build instead of silently dropping local settings. Old commands such as `--flake ~/.config/nixos` must be changed to
the `path:` form. No `--impure` flag is required.

Gitignored does not mean secret: evaluated host mappings enter the local Nix
store and `/etc/hosts`, which are readable by other local users. Do not put
credentials in this file.

## SIS and Tailscale split DNS

`../tailscale.nix` runs loopback-only dnsmasq. The system resolver must stay on
localhost: an internal DNS server prepended by the VPN can answer NXDOMAIN for
a tailnet name, which is a final answer, not a reason to try localhost next.

Copy `dns.example.nix` to **gitignored** `dns.local.nix` and configure `servers`
(corporate IPv4 DNS addresses) and `domains` (corporate suffixes). Keep internal
addresses outside Git; they still enter the local Nix store, so never include
credentials. Missing or invalid local DNS settings fail the build.

- `ts.net` and its subdomains go only to Tailscale MagicDNS (`100.100.100.100`).
- Suffixes from `dns.local.nix` go only to the configured corporate DNS servers.
- Unmatched names keep the normal NetworkManager/openresolv upstreams.
- Tailscale keeps `--accept-dns=false`; no route, exit-node, or firewall change is needed.

The generated VPN configuration disables both direct and PPP DNS installation.
Do not override these settings on the VPN command line. Activation runs
`resolvconf -u` to remove DNS lines that an already-connected VPN prepended,
without disconnecting PPP. The domain rules are configured to remain effective across reconnects.
When disconnected, private names can fail as expected; they are not leaked to a
public fallback. Existing `networking.hosts` mappings remain in effect.

After activation, check:

```bash
head /etc/resolv.conf                         # localhost, not corporate DNS first
getent ahostsv4 pi.tailb7373.ts.net
getent ahostsv4 example.com
node ~/repos/pi-remote/bin/pi-remote-worker status
```

Also check a work-only hostname and compare `resolvconf -l` with
`/etc/dnsmasq-resolv.conf`. DNS repair does not resolve unrelated TCP/TLS/HTTP
timeouts to a known private IP. Reconnect validation requires operator approval
because it can interrupt active work.

The route renderer has regression checks in `vpn-routes-tests.nix` (route order,
final `exec`, CIDR validation, and rejection of empty or unsafe input). Run:

```bash
nix eval --impure --json --expr 'let
  f = builtins.getFlake ("path:" + builtins.getEnv "HOME" + "/.config/nixos");
in import (builtins.getEnv "HOME" + "/.config/nixos/modules/sis/vpn-routes-tests.nix")
  { lib = f.inputs.nixpkgs.lib; }'
```

The pure VPN renderer has regression checks in `vpn-config-tests.nix` (retained
connection settings, conflicting/duplicate DNS options and empty input). Run:

```bash
nix eval --impure --json --expr 'let
  f = builtins.getFlake ("path:" + builtins.getEnv "HOME" + "/.config/nixos");
in import (builtins.getEnv "HOME" + "/.config/nixos/modules/sis/vpn-config-tests.nix")
  { lib = f.inputs.nixpkgs.lib; }'
```
