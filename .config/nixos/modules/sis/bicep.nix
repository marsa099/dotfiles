# Bicep CLI — upstream Microsoft self-contained Linux binary, run inside an FHS env.
#
# Why not pkgs.bicep? nixpkgs is stuck at 0.36.177 across stable, unstable
# and master (as of 2026-04-28). Upstream is 0.42.1. Without newer types,
# any resource pinned to 2025-* API versions throws BCP081 warnings on every
# build. We don't want to wait for a nixpkgs bump.
#
# Why not let `az bicep install` self-download? That's exactly what it tries
# by default — and the resulting binary crashes on NixOS in libicu lookup
# (`Couldn't find a valid ICU package installed`) because the Microsoft
# self-contained .NET binary has no Nix-friendly RUNPATH.
#
# Why not autoPatchelfHook on the binary? Microsoft ships bicep as a
# .NET single-file self-contained bundle: a normal ELF with the bundle
# data appended at the end. patchelf rewrites ELF program headers, which
# shifts the bundle offset and breaks bundle parsing — manifesting as
# "Failure processing application bundle; arithmetic overflow while reading
# bundle." The binary becomes unusable.
#
# Solution: leave the binary byte-identical to upstream and run it inside
# a buildFHSEnv chroot that provides the libraries it expects in /usr/lib.
# Slightly heavier per-invocation than a patchelfed binary (chroot setup
# cost, ~tens of ms), trivially correct, and survives upstream bumps.
#
# Upgrade workflow:
#   1. Bump `version`
#   2. nix-prefetch-url --type sha256 https://github.com/Azure/bicep/releases/download/v<version>/bicep-linux-x64
#   3. Replace `sha256` with the printed hash
#   4. nixos-rebuild switch && bicep --version

{ pkgs, ... }:

let
  bicep-bin = pkgs.fetchurl {
    url = "https://github.com/Azure/bicep/releases/download/v0.42.1/bicep-linux-x64";
    sha256 = "0fbi7qbssx6dw343w7civ57x1i4a81a463fwf2yy4vlsqsr0xndf";
  };

  bicep-bin-store = pkgs.runCommandLocal "bicep-bin-${"0.42.1"}" { } ''
    install -Dm755 ${bicep-bin} $out/bin/bicep
  '';

  bicep-fhs = pkgs.buildFHSEnv {
    name = "bicep";
    targetPkgs = p: with p; [
      icu
      zlib
      openssl
      stdenv.cc.cc.lib
    ];
    runScript = "${bicep-bin-store}/bin/bicep";
    meta = {
      description = "Bicep CLI 0.42.1 (upstream Microsoft binary, run in FHS env)";
      homepage = "https://github.com/Azure/bicep";
      mainProgram = "bicep";
    };
  };
in
{
  environment.systemPackages = [ bicep-fhs ];
}
