# Vercel CLI and its dependencies (Node.js, pnpm).

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nodejs
    nodePackages.pnpm
    nodePackages.vercel
  ];
}
