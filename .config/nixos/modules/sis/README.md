# SIS local network settings

`default.nix` imports `hosts.local.nix` as the `networking.hosts` attribute set.
The local file is gitignored. Do not force-add it. `hosts.example.nix` contains
only a placeholder and can be copied on a new machine:

```bash
cd ~/.config/nixos/modules/sis
cp -n hosts.example.nix hosts.local.nix
```

## Local VPN configuration

`default.nix` also installs the gitignored `vpn.local.conf` as
`/etc/openfortivpn/config`, readable only by root (mode `0600`). Keep the VPN
server address and non-secret connection settings in this local file. On a new
machine, copy `vpn.example.conf` to `vpn.local.conf` and replace its placeholder
host before rebuilding. Never force-add `vpn.local.conf` to Git.

The SIS route hook requires `set-routes = 0` and `pppd-ipparam = sis`. After the
first rebuild, edit `vpn.local.conf` and rebuild rather than manually editing
`/etc/openfortivpn/config`. The module does not start the VPN automatically.

**Gitignored is not secret storage.** Despite the installed file's `0600` mode,
the source configuration enters the world-readable Nix store. Never put
passwords, tokens, or private keys in it; keep authentication outside Nix inputs.

## Build with the local files

Git flakes omit ignored files. Use the explicit **`path:`** flake form, which
includes both local files, rather than the Git-inferred directory form:

```bash
sudo nixos-rebuild switch --flake "path:$HOME/.config/nixos#nixos"
```

Missing local files fail the build instead of silently dropping local settings. Old commands such as `--flake ~/.config/nixos` must be changed to
the `path:` form. No `--impure` flag is required.

Gitignored does not mean secret: evaluated host mappings enter the local Nix
store and `/etc/hosts`, which are readable by other local users. Do not put
credentials in this file.

## Tailscale split DNS

`../tailscale.nix` runs a loopback-only dnsmasq resolver. Only `ts.net` and its
subdomains go to Tailscale MagicDNS (`100.100.100.100`). Other domains use the
existing NetworkManager/PPP DNS servers supplied by openresolv, in their
configured order. Tailscale's global DNS installation is disabled with
`--accept-dns=false`; use full `*.ts.net` names rather than relying on its search
suffix. No DNS firewall port is opened.

After activation, check:

```bash
getent ahostsv4 pi.tailb7373.ts.net
getent ahostsv4 example.com
node ~/repos/pi-remote/bin/pi-remote-worker status
```

Also check the local hostnames in `hosts.local.nix` and a work-only hostname
while the work VPN is connected. Compare `resolvconf -l` and
`/etc/dnsmasq-resolv.conf` if upstream DNS changes.
