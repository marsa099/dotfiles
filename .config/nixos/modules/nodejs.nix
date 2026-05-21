# Node.js toolchain. Vercel CLI is installed separately via `pnpm add -g vercel`
# because nodePackages was removed from nixpkgs (2026-03-03) and there is no
# top-level `vercel` package — pnpm-global keeps it on latest reliably.
#
# nodejs_latest = Node 24 LTS (current Active LTS as of late 2025).
# unstable.pnpm = pnpm 11.x (latest major); stable 25.11 still ships pnpm 10.

{ pkgs, unstable, ... }:

{
  environment.systemPackages = [
    pkgs.nodejs_latest
    unstable.pnpm
  ];
}
