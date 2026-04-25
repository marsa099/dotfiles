# NixOS Review

A running list of NixOS-specific friction encountered with this setup.
Each entry: **what broke**, **how it was patched**, **whose fault it is**,
and **would it have been a problem on Arch?** (as a sanity check — Arch
is the closest "rolling, FHS-compliant, you-do-it-yourself" distro, so
if Arch has no issue, the friction is genuinely NixOS-flavored.)

The goal is to spot recurring patterns so future "weird app X doesn't
work on NixOS" moments take 5 minutes instead of an evening.

---

## libsecret missing for FHS-assuming Microsoft binaries

### Symptoms

| Date       | App                | Failure mode                                                                                  |
| ---------- | ------------------ | --------------------------------------------------------------------------------------------- |
| 2026-04-01 | .NET SDK / MSAL    | `dotnet restore --interactive` could not store NuGet feed creds; fell back to plaintext       |
| 2026-04-25 | Azure Data Studio  | "OS keyring is not available for encryption" popup; secrets stored in-memory only             |

Both are the same root cause. Microsoft's Linux binaries `dlopen("libsecret-1.so.0")`
at runtime, expecting it on the loader path under `/usr/lib`. On NixOS that path
doesn't exist, and the binaries' RUNPATH doesn't reach `/run/current-system/sw/lib`
where the system's libsecret actually lives.

In the ADS case, the smoking gun in `ELECTRON_ENABLE_LOGGING=1` output:

    WARNING:key_storage_linux.cc(183)] OSCrypt tried Libsecret but couldn't initialise.

That's Chromium's OSCrypt failing the dlopen silently, then falling back to
"basic" plaintext storage and showing the popup.

### Fixes

- `modules/dotnet.nix` (commit `5fc68c6`, 2026-04-01) — wraps `dotnet-sdk_10`
  with `makeBinaryWrapper --prefix LD_LIBRARY_PATH ${pkgs.libsecret}/lib`.
  Simple outer-wrap works because `pkgs.dotnet-sdk_10` doesn't itself set
  `LD_LIBRARY_PATH` — our prefix is the only one in play.
- `modules/azure-data-studio.nix` — **outer wrapping does NOT work for ADS.**
  The nixpkgs derivation's inner `preFixup` calls
  `makeWrapper ... --set LD_LIBRARY_PATH ${rpath}`, which clobbers any
  outer-wrapper prefix. Required fix: `overrideAttrs` the package and
  string-replace the rpath inside `preFixup` so the inner `--set` itself
  includes libsecret. This forces a full ADS rebuild from source on every
  `nixos-rebuild switch`.

### Why ADS is uglier than dotnet

Both apps need libsecret. But the fix shape is wildly different:

| App  | Inner LD_LIBRARY_PATH? | Fix                                    | Cost                    |
| ---- | ---------------------- | -------------------------------------- | ----------------------- |
| dotnet | None                 | Outer wrapper, `--prefix`              | Cheap (just the wrapper)|
| ADS  | `--set` to a fixed list | Override package, patch `preFixup`    | Full ADS rebuild        |

ADS is harder *purely because nixpkgs's ADS derivation chose `--set` over
`--prefix`* in its inner wrapper. A `--prefix` would have let any outer
consumer extend the path cheaply.

### Whose fault is it?

**nixpkgs (~80%) — primary fault.** Two compounding problems:

1. The `azuredatastudio` derivation has zero references to libsecret —
   unlike `vscode`, which explicitly adds libsecret to its runtime path
   (`pkgs/applications/editors/vscode/generic.nix`: `runtimeDependencies =
   [ ... libsecret ]` + `autoPatchelfHook`). Same Electron engine,
   identical need, inconsistent packaging. Tracked upstream as
   [nixpkgs#294948](https://github.com/NixOS/nixpkgs/issues/294948), open.
2. The ADS derivation's inner wrapper uses `--set` instead of `--prefix`,
   making it actively hostile to downstream extension. Anyone hitting the
   missing-libsecret problem can't fix it with a 5-line outer wrapper —
   they have to override the package and rebuild ADS from scratch.

The first issue is just a missing dep. The second is a packaging anti-pattern
that turns a one-line fix into a full rebuild.

**Microsoft / Electron (~15%).** Their Linux binaries assume FHS layout and
`dlopen` libsecret with no fallback path. Standard Electron behavior — but it
bites every distro that isn't FHS-pure. A graceful fallback when libsecret
can't load (instead of just popping a popup and silently storing in plaintext)
would have made this a non-issue regardless of distro.

**NixOS itself (~5%).** By design no `/usr/lib`. `nix-ld` exists to soften
this for foreign binaries, but its default library set doesn't include
libsecret, and it doesn't apply to already-Nix-wrapped binaries like ADS anyway.

### On Arch Linux: would this happen?

**No.** On Arch:

- `pacman -S libsecret` puts `libsecret-1.so.0` in `/usr/lib/`, which is
  on the default loader path for every dynamically-linked binary.
- ADS from the AUR (`azuredatastudio-bin`) is the upstream Microsoft tarball
  with no Arch-specific repackaging — `dlopen("libsecret-1.so.0")` finds
  the system lib immediately.
- gnome-keyring (or kwallet, or KeePassXC's secret service) is a one-line
  install + autostart and just works.

The whole class of "Microsoft binary `dlopen`s a system lib but can't find
it" is invisible on Arch. The friction is 100% NixOS-flavored — caused by
NixOS's deliberate rejection of FHS, plus the nixpkgs gap on this specific
package. The .NET fix and the ADS fix would both be no-ops on Arch.

### Reference: how others handle it

`jlodenius/.nixos` (a peer NixOS config) installs ADS raw with no override
and ships `pkgs.libsecret` + `services.gnome.gnome-keyring.enable`. That
configuration has the *prerequisites* for ADS to find a keyring — but
without rebuilding ADS, libsecret still isn't on the binary's loader path,
so the popup will fire and secrets land in plaintext. They likely don't
notice or don't care. Confirms that the "works on my machine" bar for
ADS on NixOS is "popup dismissed, plaintext storage".

### Lesson

When adding any Microsoft Electron / .NET / dlopen-heavy app:

1. Run it once with `ELECTRON_ENABLE_LOGGING=1 <app> --verbose 2>&1 | tee /tmp/x.log`
2. Grep the log for `OSCrypt`, `Libsecret`, `key_storage` warnings
3. If any appear, wrap the binary the same way `dotnet.nix` does

If we keep hitting this for new apps, consider promoting `pkgs.libsecret`
into `programs.nix-ld.libraries` system-wide as a backstop.
