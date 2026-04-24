# Azure Data Studio (SQL management IDE).
#
# Requires libsecret + gnome-keyring for credential storage
# (e.g. saved SQL server connections). These are also declared in
# dotnet.nix but duplicated here so this module is self-contained.

{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    azuredatastudio
    libsecret
  ];

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
}
