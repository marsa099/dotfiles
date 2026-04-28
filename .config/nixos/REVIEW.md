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

---

## Bicep CLI: stale nixpkgs + libicu dlopen + single-file bundle

### Symptoms

| Date       | App           | Failure mode                                                                                       |
| ---------- | ------------- | -------------------------------------------------------------------------------------------------- |
| 2026-04-28 | `az bicep`    | `Couldn't find a valid ICU package installed` — az auto-downloaded bicep crashes immediately      |
| 2026-04-28 | `pkgs.bicep`  | Works, but stuck at 0.36.177 in stable/unstable/master; floods 8× BCP081 on 2025-* API versions   |
| 2026-04-28 | upstream bin + autoPatchelfHook | `Failure processing application bundle; arithmetic overflow while reading bundle` |

Three faces of the same problem: **how do you run a recent Microsoft Bicep on NixOS?**

1. **az self-install** drops a self-contained .NET binary in `~/.azure/bin/`. Like every Microsoft FHS-assuming Linux binary, it `dlopen`s `libicu` and dies because NixOS has no `/usr/lib`.
2. **`pkgs.bicep`** is a proper Nix build, but nixpkgs hasn't bumped it past 0.36.177 — across stable, unstable, AND master. Every resource pinned to a 2025-* API version warns BCP081 because 0.36.177 lacks the type metadata.
3. **autoPatchelfHook on upstream binary** seems like the obvious fix: download `bicep-linux-x64`, patchelf its RUNPATH against `pkgs.icu`, done. Except bicep is a **.NET single-file self-contained bundle** — a normal ELF with the bundle's payload appended after the ELF data. patchelf rewrites program headers, the file size shifts, the bundle's "where does my payload start?" offset becomes wrong, and bundle parsing fails with arithmetic overflow.

### Fix

`modules/bicep.nix` (commit `<pending>`, 2026-04-28) — keeps the upstream binary **byte-identical** and runs it inside a `buildFHSEnv` chroot that provides `icu`, `zlib`, `openssl`, `stdenv.cc.cc.lib` under `/usr/lib`. The binary's own `dlopen` then resolves naturally inside the FHS env.

Cost: chroot setup adds tens of ms per invocation. Negligible for `az bicep build`.

### Why the obvious fix doesn't work

`autoPatchelfHook` is the standard nixpkgs answer for "foreign binary needs Nix libs." It works on stand-alone ELFs because patchelf's modifications stay within the ELF format. **It breaks on .NET single-file bundles** because the bundle reader computes its data offset from the file size (or a footer offset relative to file end), and patchelf changes that.

This is upstream Microsoft's call: single-file bundling is a deployment convenience that's hostile to any post-build binary surgery. Other tools (Azure CLI itself uses Python; `dotnet` uses many separate files) don't hit this. Anything that ships as a single-file self-contained binary will.

### Whose fault is it?

**Microsoft (~50%).** Single-file bundle format is fragile by design — any post-build tool that touches the ELF risks invalidating the bundle. Tools that ship this way force consumers into either FHS envs or wholesale rebuilding.

**nixpkgs (~30%).** Six minor versions behind upstream on a tool used heavily for Azure deployments. The blocker is that nixpkgs builds bicep from source via `buildDotnetModule`, which needs a NuGet deps lock regenerated for every version — a known maintenance pain point. No issue tracked yet (one could be filed).

**NixOS itself (~20%).** No `/usr/lib` is the trigger; everything else flows from there. nix-ld doesn't help because the Microsoft binary doesn't go through nix-ld's loader stub.

### On Arch Linux: would this happen?

**No.** On Arch:

- `pacman -S bicep` exists in AUR (`bicep-bin`) and tracks upstream within days, so 0.42.1 is available.
- Even if you `az bicep install`, libicu and friends live at `/usr/lib/libicuuc.so` etc. and the loader finds them with no extra work.

Class of problem (Microsoft self-contained binary + system lib `dlopen`) is invisible on Arch. Same root cause family as the ADS / libsecret issue — different lib, same FHS assumption.

### Lesson

For Microsoft `*.NET single-file self-contained binaries on NixOS, **default to `buildFHSEnv` rather than `autoPatchelfHook`**. The chroot cost is cheap; the patchelf failure mode is silent and confusing. autoPatchelfHook is the right tool for plain dynamically-linked ELFs, not for bundles with appended payloads.

Reusable mental check: `file /path/to/binary` shows just `ELF 64-bit LSB executable...`. To detect single-file bundle, check for the `.NET` signature near end-of-file:

```bash
strings -a -n 8 ./bin | grep -i 'bundle\|netcoreapp\|microsoft'
```

If matches, assume bundled and skip patchelf.
