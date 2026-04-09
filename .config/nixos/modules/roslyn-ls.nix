# Roslyn LSP wrapper for NixOS.
#
# Two problems with the nixpkgs roslyn-ls on NixOS:
#
# 1. The wrapper's dotnetFromEnv function resolves DOTNET_ROOT to the
#    dotnet-sdk-wrapped/bin/ directory instead of share/dotnet/, so
#    Roslyn's MSBuild host can't find the SDK ("No .NET SDKs were found").
#
# 2. .NET's FileSystemWatcher recursively watches SDK/runtime paths
#    which on NixOS point into /nix/store (660K+ directories), causing
#    500K+ inotify watches and exhausting the kernel limit.
#
# Solution: wrap roslyn-ls to use the system dotnet (which has correct
# DOTNET_ROOT from dotnet-nuget-auth.nix) and enable polling file watcher
# to avoid the inotify explosion.

{ pkgs, unstable, ... }:

let
  roslyn-ls-wrapped = pkgs.writeShellScriptBin "roslyn" ''
    exec dotnet "${unstable.roslyn-ls}/lib/roslyn-ls/Microsoft.CodeAnalysis.LanguageServer.dll" "$@"
  '';
in
{
  environment.systemPackages = [ roslyn-ls-wrapped ];
}
