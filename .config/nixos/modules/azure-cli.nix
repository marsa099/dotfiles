# Azure CLI with DevOps extension for NixOS.
#
# Uses unstable channel because stable has a Python namespace packaging bug
# (nixpkgs#490035) that breaks all `az deployment` commands (e.g. `az deployment
# sub what-if`) with "'NoneType' object has no attribute '__name__'".
#
# NixOS azure-cli can't install the Python keyring package, so
# `az devops login` fails. This wrapper reads the PAT from GNOME Keyring
# (via secret-tool) for devops/repos/pipelines commands.
#
# The azure-devops extension prefers MSAL tokens (az login) over PATs.
# When az login uses a different account than the PAT, the extension picks
# the wrong identity. AZURE_CONFIG_DIR is set to a temp dir so the extension
# can't find the MSAL cache and falls through to the PAT.
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
case "$1" in
    devops|repos|pipelines)
        AZURE_DEVOPS_EXT_PAT=$(secret-tool lookup service azure-devops type cli) \
        AZURE_CONFIG_DIR=$(mktemp -d) \
            exec ${az-unwrapped}/bin/az "$@" ;;
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
  ];
}
