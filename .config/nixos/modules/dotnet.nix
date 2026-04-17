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
# NuGet auth setup (one-time):
#   dotnet tool install --global Microsoft.Artifacts.CredentialProvider.NuGet.Tool
#   dotnet restore --interactive

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
  environment.sessionVariables.DOTNET_ROOT = "${dotnet-wrapped}/share/dotnet";

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
