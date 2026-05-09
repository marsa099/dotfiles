# Rust toolchain.
#
# Used for building local TUI tools (currently: claudeck, the workspace
# manager in ~/repos/claudeck).
#
# nixpkgs ships rustc/cargo as a matched pair from the same release, which is
# fine for this use — we don't need rustup-style multi-channel switching here.

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    rustc
    cargo
    clippy
    rustfmt
    rust-analyzer
  ];
}
