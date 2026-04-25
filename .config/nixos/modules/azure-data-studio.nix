# Azure Data Studio (SQL management IDE).
#
# Wrapped with libsecret in LD_LIBRARY_PATH so credential storage works.
# The nixpkgs `azuredatastudio` derivation does not include libsecret in
# its RUNPATH (unlike `vscode`, which does), so Chromium's OSCrypt fails
# to dlopen libsecret-1.so.0 and falls back to plaintext in-memory storage.
# Tracked upstream as nixpkgs#294948. See REVIEW.md for the full analysis.

{ pkgs, lib, ... }:

let
  # An outer makeWrapper --prefix LD_LIBRARY_PATH does NOT work here because
  # the nixpkgs ADS derivation's inner preFixup calls
  #     makeWrapper ... --set LD_LIBRARY_PATH ${rpath}
  # which clobbers whatever an outer wrapper injects. Instead, override the
  # package and substitute the new rpath into the original preFixup string,
  # so the inner --set itself includes libsecret.
  azuredatastudio-wrapped = pkgs.azuredatastudio.overrideAttrs (old: rec {
    rpath = "${old.rpath}:${lib.makeLibraryPath [ pkgs.libsecret ]}";
    preFixup = lib.replaceStrings [ old.rpath ] [ rpath ] old.preFixup;
  });
in
{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = [
    azuredatastudio-wrapped
    pkgs.libsecret
  ];

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
}
