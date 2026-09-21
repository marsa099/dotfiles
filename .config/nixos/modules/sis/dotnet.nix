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
#   uses the Microsoft Artifacts Credential Provider. The env vars below enable
#   both layers required for non-interactive reuse:
#     - SESSIONTOKENCACHE_ENABLED=true -> cache the short-lived ADO feed token in
#       ~/.local/share/MicrosoftCredentialProvider/SessionTokenCache.dat. Microsoft
#       documents that disabling this cache prompts for authentication every time.
#     - MSAL_ENABLED + MSAL_FILECACHE_ENABLED=true -> remember the longer-lived
#       AAD login securely in gnome-keyring (via libsecret, wired below).
#   This is isolated from the az CLI login: the provider uses its own AAD client
#   id + keyring collection, while az keeps its cache under ~/.azure/.
#
#   The provider comes from nixpkgs (azure-artifacts-credprovider), NOT from
#   `dotnet tool install --global`. NuGet only auto-discovers plugins named
#   nuget-plugin-* on PATH, and the nixpkgs files aren't named that, so
#   NUGET_PLUGIN_PATHS points at the provider explicitly. Nix interpolates the
#   store path, which makes it a real reference that the GC can't collect.
#
#   Point at the managed DLL in lib/, NOT the bash wrapper in bin/. Since SDK 10
#   NuGet starts non-.dll plugin paths as `dotnet <path> -Plugin`, and .NET 10
#   treats `dotnet <file>` as a file-based C# app: it tries to compile the bash
#   script, prints CS errors to stdout, and NuGet fails with
#   "JsonReaderException: Error parsing comment". .dll paths run via
#   `dotnet exec`. The DLL targets net8.0 but its runtimeconfig has
#   rollForward=Major, so it runs on the SDK's net10 runtime.
#
#   NEVER use `dotnet tool install --global` on NixOS. Those shims are native
#   apphosts that the SDK patchelfs against whatever glibc was current that day;
#   once Nix garbage-collects that glibc the shim dies with a misleading
#   "No such file or directory" on a file that plainly exists (the missing file
#   is the ELF interpreter, not the binary). That is exactly how the previously
#   hand-installed credential provider broke, and dotnet-ef with it. The nixpkgs
#   package avoids it: the provider is a managed .dll run through dotnet (the
#   bin/ bash wrapper does the same, but see above for why NuGet must get the
#   .dll path rather than the wrapper).
#   For per-repo tools like dotnet-ef, use a repo-local tool manifest
#   (`dotnet new tool-manifest` + `dotnet tool install dotnet-ef`, invoked as
#   `dotnet ef`) — also managed-dll-via-dotnet, so also GC-proof.
#
#   One-time setup (after a rebuild + re-login so the session vars apply):
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

    # Cache the short-lived ADO feed token so separate dotnet processes reuse
    # an interactive login. The longer-lived AAD login remains in gnome-keyring.
    NUGET_CREDENTIALPROVIDER_SESSIONTOKENCACHE_ENABLED = "true";
    NUGET_CREDENTIALPROVIDER_MSAL_ENABLED = "true";
    NUGET_CREDENTIALPROVIDER_MSAL_FILECACHE_ENABLED = "true";

    # NuGet finds credential-provider plugins two ways: nuget-plugin-* on PATH,
    # or this variable. Nothing in the nixpkgs package is named nuget-plugin-*,
    # so PATH discovery never fires and this is the wiring that makes the Azure
    # DevOps Artifacts feeds authenticate at all. See the header note on why
    # this must be the DLL rather than bin/CredentialProvider.Microsoft.
    NUGET_PLUGIN_PATHS = "${pkgs.azure-artifacts-credprovider}/lib/azure-artifacts-credprovider/CredentialProvider.Microsoft.dll";
  };

  environment.systemPackages = [
    dotnet-wrapped
    pkgs.libsecret # provides libsecret-1.so for MSAL keyring access
    pkgs.azure-artifacts-credprovider # NuGet auth for Azure DevOps Artifacts
  ];

  # nix-ld provides a dynamic linker stub so dotnet-compiled binaries
  # (which are dynamically linked) can run without patchelf
  programs.nix-ld.enable = true;

  # gnome-keyring stores the auth tokens, PAM auto-unlocks it at login
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
}
