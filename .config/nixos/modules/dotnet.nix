# .NET SDK configuration for NixOS.
#
# Wraps dotnet-sdk with two fixes:
#
# 1. LD_LIBRARY_PATH includes libsecret so MSAL can store NuGet feed
#    auth tokens in gnome-keyring instead of plain text.
#
# 2. DOTNET_ROLL_FORWARD=LatestMajor lets apps targeting older frameworks
#    (e.g. net8.0) run on the .NET 10 runtime. This is needed because
#    NixOS combinePackages can't provide multiple runtimes — hostfxr
#    resolves through symlinks to the original single-SDK package.
#
# Also sets DOTNET_ROOT as a session variable so other tools (roslyn-ls
# etc.) can find the SDK.
#
# NuGet auth for Azure DevOps Artifacts feeds (e.g. SIS.Common@Local):
#   uses the Microsoft Artifacts Credential Provider. The env vars below force
#   keyring-only credential storage:
#     - SESSIONTOKENCACHE_ENABLED=false  -> never write the feed token to disk
#       (it was persisted plaintext in ~/.local/share/MicrosoftCredentialProvider/
#        SessionTokenCache.dat; disabled so it's re-derived in memory each restore)
#     - MSAL_ENABLED + MSAL_FILECACHE_ENABLED=true -> remember the AAD login in
#       gnome-keyring (via libsecret, wired below), so restores stay
#       non-interactive without any plaintext secret on disk.
#   This is isolated from the az CLI login: the provider uses its own AAD client
#   id + keyring collection, while az keeps its cache under ~/.azure/.
#
#   One-time setup:
#     dotnet tool install --global Microsoft.Artifacts.CredentialProvider.NuGet.Tool
#     dotnet restore --interactive   # device-code login; token lands in keyring

{ pkgs, ... }:

let
  dotnet-wrapped = pkgs.symlinkJoin {
    name = "dotnet-sdk-wrapped";
    paths = [ pkgs.dotnet-sdk_10 ];
    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
    postBuild = ''
      rm "$out/bin/dotnet"
      makeBinaryWrapper "${pkgs.dotnet-sdk_10}/bin/dotnet" "$out/bin/dotnet" \
        --prefix LD_LIBRARY_PATH : "${pkgs.libsecret}/lib" \
        --set DOTNET_ROLL_FORWARD LatestMajor
    '';
  };
in
{
  environment.sessionVariables = {
    DOTNET_ROOT = "${dotnet-wrapped}/share/dotnet";

    # Force the Artifacts Credential Provider to keyring-only storage:
    # no plaintext feed-token file; remember the AAD login in gnome-keyring.
    NUGET_CREDENTIALPROVIDER_SESSIONTOKENCACHE_ENABLED = "false";
    NUGET_CREDENTIALPROVIDER_MSAL_ENABLED = "true";
    NUGET_CREDENTIALPROVIDER_MSAL_FILECACHE_ENABLED = "true";
  };

  environment.systemPackages = [
    dotnet-wrapped
    pkgs.libsecret # provides libsecret-1.so for MSAL keyring access
  ];

  # nix-ld provides a dynamic linker stub so dotnet-compiled binaries
  # (which are dynamically linked) can run without patchelf
  programs.nix-ld.enable = true;

  # gnome-keyring stores the auth tokens, PAM auto-unlocks it at login
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
}
