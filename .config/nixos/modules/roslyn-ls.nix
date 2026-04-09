# Roslyn LSP wrapper for NixOS.
#
# Problem: the nixpkgs roslyn-ls wrapper runs the DLL with dotnet-runtime,
# not the full SDK. Roslyn's MSBuild host needs the SDK to load projects,
# so projects fail with "No .NET SDKs were found".
#
# Solution: bypass the nixpkgs wrapper and run the roslyn-ls DLL directly
# with the system dotnet SDK (provided by dotnet.nix).
#
# Uses unstable nixpkgs because stable roslyn-ls (5.3.0) requires .NET 9
# runtime which we don't have — we only have .NET 10.

{ pkgs, unstable, ... }:

let
  roslyn-ls-wrapped = pkgs.writeShellScriptBin "roslyn" ''
    exec dotnet "${unstable.roslyn-ls}/lib/roslyn-ls/Microsoft.CodeAnalysis.LanguageServer.dll" "$@"
  '';
in
{
  environment.systemPackages = [ roslyn-ls-wrapped ];
}
