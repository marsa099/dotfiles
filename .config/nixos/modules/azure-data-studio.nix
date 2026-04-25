# Azure Data Studio (SQL management IDE).
#
# Wrapped with libsecret in LD_LIBRARY_PATH so credential storage works.
# The nixpkgs `azuredatastudio` derivation does not include libsecret in
# its RUNPATH (unlike `vscode`, which does), so Chromium's OSCrypt fails
# to dlopen libsecret-1.so.0 and falls back to plaintext in-memory storage.
# Tracked upstream as nixpkgs#294948. See REVIEW.md for the full analysis.

{ pkgs, ... }:

let
  azuredatastudio-wrapped = pkgs.symlinkJoin {
    name = "azuredatastudio-libsecret";
    paths = [ pkgs.azuredatastudio ];
    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
    postBuild = ''
      rm "$out/bin/azuredatastudio"
      makeBinaryWrapper "${pkgs.azuredatastudio}/bin/azuredatastudio" "$out/bin/azuredatastudio" \
        --prefix LD_LIBRARY_PATH : "${pkgs.libsecret}/lib"
    '';
  };
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
