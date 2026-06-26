# Azure CLI with DevOps extension for NixOS.
#
# Uses unstable channel because stable has a Python namespace packaging bug
# (nixpkgs#490035) that breaks all `az deployment` commands (e.g. `az deployment
# sub what-if`) with "'NoneType' object has no attribute '__name__'".
#
# NixOS azure-cli can't install the Python keyring package, so
# `az devops login` fails. This wrapper reads the PAT from GNOME Keyring
# (via secret-tool) for devops/repos/pipelines/rest commands.
#
# The azure-devops extension prefers MSAL tokens (az login) over PATs.
# When az login uses a different account than the PAT, the extension picks
# the wrong identity. AZURE_CONFIG_DIR is pointed at a dedicated dir so the
# extension can't find the MSAL cache and falls through to the PAT.
#
# Config dir layout (AZURE_CONFIG_DIR decides where the MSAL token cache,
# azureProfile.json, az config, logs, etc. live):
#   ~/.azure          — the CLI default (used whenever the wrapper doesn't
#                       override AZURE_CONFIG_DIR). Holds the MSAL token cache
#                       written by `az login`; the `rest` (Graph/ARM) and the
#                       catch-all `*)` cases authenticate as this identity.
#   ~/.config/az-devops — dedicated, persistent dir for devops/repos/pipelines.
#                       Deliberately isolated from ~/.azure so the MSAL cache
#                       isn't visible there, forcing the PAT identity. Made
#                       persistent (not a throwaway mktemp -d) so that
#                       `az devops configure --defaults organization=... project=...`
#                       survives between invocations.
# Note: ~/.azure is the default only because nothing exports AZURE_CONFIG_DIR.
# If that var were set in the shell environment, the `rest`/`*)` cases would
# honour it; the devops/repos/pipelines case always pins ~/.config/az-devops
# regardless.
#
# `az rest` normally injects an MSAL bearer token from `az login`. For ADO
# URLs we override that with --skip-authorization-header and a Basic auth
# header built from the PAT, so `az rest` hits Azure DevOps APIs as the PAT
# identity. For everything else (Graph, ARM, etc.) we fall through to the
# standard MSAL bearer behavior — injecting Basic auth there breaks Graph
# with "JWT is not well formed" since Graph expects a bearer JWT.
#
# PATs stored in GNOME Keyring:
#   cli (code full + build/release read):
#     secret-tool store --label="Azure DevOps PAT (cli)" service azure-devops type cli
#   waybar (build/release read):
#     secret-tool store --label="Azure DevOps PAT (waybar)" service azure-devops type waybar

{ pkgs, unstable, ... }:

let
  az-unwrapped = unstable.azure-cli.withExtensions [ unstable.azure-cli.extensions.azure-devops ];
  az-wrapped = pkgs.symlinkJoin {
    name = "azure-cli-wrapped";
    paths = [ az-unwrapped ];
    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
    postBuild = ''
      rm "$out/bin/az"
      cat > "$out/bin/az" <<'WRAPPER'
#!/usr/bin/env bash
# Use Nix-managed bicep (pkgs.bicep) instead of az's self-downloaded one;
# avoids libicu crash because the nixpkgs build is properly patchelf'd.
export AZURE_BICEP_USE_BINARY_FROM_PATH=true
case "$1" in
    devops|repos|pipelines)
        # Persistent, isolated config dir — see "Config dir layout" header note.
        az_devops_cfg="''${XDG_CONFIG_HOME:-$HOME/.config}/az-devops"
        mkdir -p "$az_devops_cfg"
        AZURE_DEVOPS_EXT_PAT=$(secret-tool lookup service azure-devops type cli) \
        AZURE_CONFIG_DIR="$az_devops_cfg" \
            exec ${az-unwrapped}/bin/az "$@" ;;
    rest)
        shift
        # Inject PAT only for ADO URLs; let MSAL bearer flow through for everything else
        # (Graph, ARM, etc. — they reject Basic auth with "JWT not well formed").
        is_ado=false
        for arg in "$@"; do
            case "$arg" in
                *dev.azure.com*|*visualstudio.com*|*vsrm.dev.azure.com*)
                    is_ado=true; break ;;
            esac
        done
        if $is_ado; then
            PAT=$(secret-tool lookup service azure-devops type cli)
            AUTH=$(printf ':%s' "$PAT" | base64 -w0)
            exec ${az-unwrapped}/bin/az rest \
                --skip-authorization-header \
                --headers "Authorization=Basic $AUTH" \
                "$@"
        else
            exec ${az-unwrapped}/bin/az rest "$@"
        fi
        ;;
    *)
        exec ${az-unwrapped}/bin/az "$@" ;;
esac
WRAPPER
      chmod +x "$out/bin/az"
    '';
  };
in
{
  environment.systemPackages = [
    az-wrapped
    # bicep is provided by ./bicep.nix (upstream binary, newer than nixpkgs)
  ];

  # Default all az output to human-readable tables. Set as an env var rather
  # than `az config set core.output=table` because the wrapper splits the
  # config dir (devops/repos/pipelines read ~/.config/az-devops, everything
  # else ~/.azure) — a config-file setting would only cover one of them, the
  # env var covers both. Per-command `-o json` still overrides it.
  environment.variables.AZURE_CORE_OUTPUT = "table";
}
