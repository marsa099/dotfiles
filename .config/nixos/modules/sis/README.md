# SIS local host mappings

`default.nix` imports `hosts.local.nix` as the `networking.hosts` attribute set.
The local file is gitignored. Do not force-add it. `hosts.example.nix` contains
only a placeholder and can be copied on a new machine:

```bash
cd ~/.config/nixos/modules/sis
cp -n hosts.example.nix hosts.local.nix
```

## Build with the local mappings

Git flakes omit ignored files. Use the explicit **`path:`** flake form, which
includes the local file, rather than the Git-inferred directory form:

```bash
sudo nixos-rebuild switch --flake "path:$HOME/.config/nixos#nixos"
```

A missing local file deliberately fails evaluation instead of silently removing
host mappings. Old commands such as `--flake ~/.config/nixos` must be changed to
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
