# NixOS Review

A running list of NixOS-specific friction encountered with this setup.
Each entry: **what broke**, **how it was patched**, **whose fault it is**.

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
  with `--prefix LD_LIBRARY_PATH ${pkgs.libsecret}/lib`
- `modules/azure-data-studio.nix` — same wrapper pattern applied to `azuredatastudio`

### Whose fault is it?

**nixpkgs (~70%) — primary fault.** The `vscode` derivation in nixpkgs
explicitly adds libsecret to its runtime path
(`pkgs/applications/editors/vscode/generic.nix`: `runtimeDependencies = [ ... libsecret ]`
combined with `autoPatchelfHook`). The `azuredatastudio` derivation does not —
zero references to libsecret in `pkgs/by-name/az/azuredatastudio/package.nix`.
Same Electron engine, identical runtime need, inconsistent packaging.
This is tracked upstream as [nixpkgs#294948](https://github.com/NixOS/nixpkgs/issues/294948),
still open.

**Microsoft / Electron (~20%).** Their Linux binaries assume FHS layout and
`dlopen` libsecret with no fallback path. Standard Electron behavior — but it
bites every distro that isn't FHS-pure. A more flexible RUNPATH or a graceful
fallback when libsecret can't load would have made this a non-issue.

**NixOS itself (~10%).** By design no `/usr/lib`. `nix-ld` exists to soften
this for foreign binaries, but its default library set doesn't include libsecret,
and it doesn't apply to already-Nix-wrapped binaries like ADS anyway.

### Lesson

When adding any Microsoft Electron / .NET / dlopen-heavy app:

1. Run it once with `ELECTRON_ENABLE_LOGGING=1 <app> --verbose 2>&1 | tee /tmp/x.log`
2. Grep the log for `OSCrypt`, `Libsecret`, `key_storage` warnings
3. If any appear, wrap the binary the same way `dotnet.nix` does

If we keep hitting this for new apps, consider promoting `pkgs.libsecret`
into `programs.nix-ld.libraries` system-wide as a backstop.
