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
# the wrong identity. AZURE_CONFIG_DIR is set to a temp dir so the extension
# can't find the MSAL cache and falls through to the PAT.
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
        AZURE_DEVOPS_EXT_PAT=$(secret-tool lookup service azure-devops type cli) \
        AZURE_CONFIG_DIR=$(mktemp -d) \
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
}
