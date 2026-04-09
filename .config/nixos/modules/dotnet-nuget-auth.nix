# Secure NuGet feed authentication for Azure DevOps.
#
# Problem: dotnet restore needs to authenticate against private Azure DevOps
# NuGet feeds. Microsoft's auth library (MSAL) stores tokens in gnome-keyring
# via libsecret. But on NixOS, libraries aren't in /usr/lib, so MSAL can't
# find libsecret and falls back to storing tokens in plain text.
#
# Solution: wrap the dotnet binary so LD_LIBRARY_PATH points to libsecret
# ONLY when running dotnet. We can't set LD_LIBRARY_PATH globally because
# that breaks library resolution for every other program on the system.
#
# Setup (one-time):
#   dotnet tool install --global Microsoft.Artifacts.CredentialProvider.NuGet.Tool
#   dotnet restore --interactive

{ pkgs, ... }:

let
  # Wrap dotnet so it can find libsecret at runtime (for MSAL keyring access).
  # This is equivalent to: LD_LIBRARY_PATH=.../libsecret/lib exec dotnet "$@"
  # DOTNET_ROLL_FORWARD=LatestMajor allows net8.0 apps to run on .NET 10 runtime,
  # avoiding NixOS combinePackages symlink issues with hostfxr path resolution.
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
    pkgs.libsecret # provides secret-tool CLI + libsecret-1.so for MSAL
  ];

  # gnome-keyring stores the auth tokens, PAM auto-unlocks it at login
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
}
