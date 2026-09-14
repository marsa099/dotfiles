# Roslyn LSP wrapper for NixOS.
#
# Problem: the nixpkgs roslyn-ls wrapper runs the DLL with dotnet-runtime,
# not the full SDK. Roslyn's MSBuild host needs the SDK to load projects,
# so projects fail with "No .NET SDKs were found".
#
# Solution: bypass the nixpkgs wrapper and run the roslyn-ls DLL directly
# with the system dotnet SDK (provided by dotnet.nix).
#
# Was on unstable because stable roslyn-ls (5.3.0) required a .NET 9 runtime we
# don't have. Since the 26.05 upgrade, stable ships 5.7.0 (same rev as unstable),
# whose DLL runs fine on our .NET 10 SDK, so this uses plain pkgs now.

{ pkgs, ... }:

let
  roslyn-ls-wrapped = pkgs.writeShellScriptBin "roslyn" ''
    exec dotnet "${pkgs.roslyn-ls}/lib/roslyn-ls/Microsoft.CodeAnalysis.LanguageServer.dll" "$@"
  '';
in
{
  environment.systemPackages = [ roslyn-ls-wrapped ];
}
