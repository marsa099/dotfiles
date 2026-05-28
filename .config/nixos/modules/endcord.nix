# Builds endcord (a Discord TUI) from upstream sparklost source (pinned via the
# `endcord-src` flake input) with daphen's customization patches applied on top
# (modules/endcord-patches/). This mirrors daphen's own setup: his features live
# as patches against upstream, not as commits on his GitHub fork (which is just a
# stale mirror of upstream).
#
# endcord has no console entry point and ships Cython extensions, so this is a
# hand-rolled derivation rather than buildPythonApplication:
#   1. apply daphen's patches (stdenv patchPhase, -p1)
#   2. compile endcord_cython/*.pyx in place (setup.py build_ext --inplace)
#   3. copy the source tree into $out/share/endcord
#   4. wrap `python main.py` as `bin/endcord`
#
# Bump upstream with: nix flake update endcord-src — then re-check the patches
# still apply against the new rev before nixos-rebuild.
{
  pkgs,
  lib,
  endcord-src,
  ...
}:

let
  pythonEnv = pkgs.python3.withPackages (ps: with ps; [
    # build
    cython
    setuptools
    # runtime (Linux subset of pyproject [project].dependencies)
    filetype
    numpy
    orjson
    protobuf
    pycryptodome
    pysocks
    python-socks
    qrcode
    soundcard
    soundfile
    urllib3
    websocket-client
    # media extra (pyproject [dependency-groups] media). endcord/media.py does a
    # top-level `import av`, so without PyAV all media viewing (images/gifs/video,
    # the `v` action) is dead. Pillow drives image rendering + inline avatars
    # (inline-pfp patch); pynacl is for voice. dave-py (DAVE E2EE voice) is
    # intentionally omitted — not in nixpkgs and not needed for media display.
    av
    pillow
    pynacl
  ]);

  endcord = pkgs.stdenv.mkDerivation {
    pname = "endcord";
    version = "1.4.2-daphen-${endcord-src.shortRev or "dirty"}";

    src = endcord-src;

    # daphen's customizations, applied in his order (vim nav, inline avatars,
    # DM/group-DM fixes). Standard a/ b/ headers, so default -p1 applies.
    patches = [
      ./endcord-patches/vim-search-and-extend-fix.patch
      ./endcord-patches/vim-insert-border-color.patch
      ./endcord-patches/vim-nav-rework.patch
      ./endcord-patches/group-dm-typing-fix.patch
      ./endcord-patches/vim-insert-clears-selection.patch
      ./endcord-patches/dm-mention-assist-fix.patch
      ./endcord-patches/inline-pfp.patch
    ];

    nativeBuildInputs = [
      pythonEnv
      pkgs.makeWrapper
    ];

    buildPhase = ''
      runHook preBuild
      ${pythonEnv}/bin/python setup.py build_ext --inplace
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/endcord
      cp -r main.py endcord endcord_cython themes $out/share/endcord/
      makeWrapper ${pythonEnv}/bin/python $out/bin/endcord \
        --add-flags "$out/share/endcord/main.py" \
        --chdir "$out/share/endcord"
      runHook postInstall
    '';

    meta = {
      description = "Feature-rich Discord TUI client (sparklost upstream + daphen's patches)";
      mainProgram = "endcord";
      homepage = "https://github.com/sparklost/endcord";
      license = lib.licenses.gpl3Only;
      platforms = lib.platforms.linux;
    };
  };
in
{
  environment.systemPackages = [ endcord ];
}
