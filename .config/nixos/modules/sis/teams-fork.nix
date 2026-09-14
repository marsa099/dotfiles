# Replaces the nixpkgs `teams-for-linux` package with a build of the
# user's fork at github:marsa099/teams-for-linux (main branch).
#
# Both versions are made available:
#   teams-for-linux         → the fork (with vim navigation)
#   teams-for-linux-stock   → upstream nixpkgs build, unchanged
#
# The launcher script at ~/.scripts/teams-launcher routes Super+T
# between the two based on a flag file, so switching is instant
# (both binaries live on PATH, no rebuild required to swap).
#
# Update the fork to a newer commit:
#   teams-fork deploy
# That helper pushes any local commits, runs `nix flake update
# teams-for-linux-fork` to bump the flake lock, and rebuilds.
#
# The derivation here mirrors upstream nixpkgs/pkgs/by-name/te/
# teams-for-linux/package.nix, but inlined because buildNpmPackage's
# npmDeps derivation is not overridable via overrideAttrs — we have
# to call buildNpmPackage with our own src + lockfile hash.

{
  pkgs,
  lib,
  teams-for-linux-fork,
  ...
}:

{
  nixpkgs.overlays = [
    (final: prev: {
      # Symlink wrapper exposing the upstream stock build under a distinct
      # binary name. Without renaming, both stock and fork would install
      # `bin/teams-for-linux` and collide in buildEnv — fork would get
      # silently dropped from the system closure.
      teams-for-linux-stock = prev.runCommand "teams-for-linux-stock" {
        meta.mainProgram = "teams-for-linux-stock";
      } ''
        mkdir -p $out/bin
        ln -s ${prev.teams-for-linux}/bin/teams-for-linux $out/bin/teams-for-linux-stock
      '';

      teams-for-linux = prev.buildNpmPackage {
        pname = "teams-for-linux";
        version = "fork-${teams-for-linux-fork.shortRev or "dirty"}";

        src = teams-for-linux-fork;

        npmDepsHash = "sha256-XLkOmpkkgUnbzzs3NAF4O2X5pk59SY7+ZWNzofdhx9w=";

        nativeBuildInputs = [
          prev.makeWrapper
          prev.copyDesktopItems
        ];

        env = {
          CSC_IDENTITY_AUTO_DISCOVERY = "false";
          ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
        };

        makeCacheWritable = true;

        buildPhase = ''
          runHook preBuild

          cp -r ${prev.electron_41.dist} electron-dist
          chmod -R u+w electron-dist
          rm electron-dist/libvulkan.so.1
          cp ${lib.getLib prev.vulkan-loader}/lib/libvulkan.so.1 electron-dist

          npm exec electron-builder -- \
              --dir \
              -c.npmRebuild=true \
              -c.asarUnpack="**/*.node" \
              -c.electronDist=electron-dist \
              -c.electronVersion=${prev.electron_41.version} \
              -c.mac.identity=null

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p $out/share/{applications,teams-for-linux}
          cp dist/*-unpacked/resources/app.asar $out/share/teams-for-linux/

          pushd build/icons
          for image in *png; do
            mkdir -p $out/share/icons/hicolor/''${image%.png}/apps
            cp -r $image $out/share/icons/hicolor/''${image%.png}/apps/teams-for-linux.png
          done
          popd

          makeWrapper '${lib.getExe prev.electron_41}' "$out/bin/teams-for-linux" \
            --prefix PATH : ${lib.makeBinPath [ prev.alsa-utils prev.which ]} \
            --add-flags "$out/share/teams-for-linux/app.asar" \
            --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations,WebRTCPipeWireCapturer --enable-wayland-ime=true}}"

          runHook postInstall
        '';

        desktopItems = [
          (prev.makeDesktopItem {
            name = "teams-for-linux";
            exec = "teams-for-linux %U";
            icon = "teams-for-linux";
            desktopName = "Microsoft Teams for Linux (fork)";
            comment = "Unofficial client for Microsoft Teams (vimNav fork)";
            categories = [ "Network" "InstantMessaging" "Chat" ];
            mimeTypes = [ "x-scheme-handler/msteams" ];
          })
        ];

        meta = {
          description = "Unofficial Microsoft Teams client for Linux (fork with vim navigation)";
          mainProgram = "teams-for-linux";
          homepage = "https://github.com/marsa099/teams-for-linux";
          license = lib.licenses.gpl3Plus;
          platforms = lib.platforms.linux;
        };
      };
    })
  ];

  environment.systemPackages = [ pkgs.teams-for-linux-stock ];
}
