# Enables secure credential storage for Azure DevOps NuGet feeds.
#
# What this does:
# - Sets DOTNET_ROOT so dotnet global tools (like the credential provider) can find the runtime
# - Enables gnome-keyring + PAM auto-unlock so MSAL can store auth tokens securely
# - Adds libsecret + LD_LIBRARY_PATH so MSAL can talk to the keyring
#
# After enabling, install the credential provider once:
#   dotnet tool install --global Microsoft.Artifacts.CredentialProvider.NuGet.Tool
#
# Then authenticate:
#   dotnet restore --interactive

{ pkgs, ... }:

{
  environment.sessionVariables.DOTNET_ROOT = "${pkgs.dotnet-sdk_10}/share/dotnet";
  environment.sessionVariables.LD_LIBRARY_PATH = "${pkgs.libsecret}/lib";

  environment.systemPackages = [ pkgs.libsecret ];

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
}
