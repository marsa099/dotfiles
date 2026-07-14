# Git commande
## Commit
When using git commit, keep the message short and descriptive. Syntax for commit messages should be "Fixes bug #1234". instead of "Implemented a fix for bug #1234".

IMPORTANT: Always use English for commit messages, never Swedish or other languages.

IMPORTANT: Do NOT add Claude Code attribution or co-authored-by lines to commit messages. Keep commits clean and concise.

# Code Style Rules
IMPORTANT: NEVER add trailing whitespaces after lines or whitespace-only lines. This applies to ALL projects FOREVER. When writing or editing code:
- No trailing whitespaces at the end of lines
- No lines that contain only whitespace characters
- Empty lines should be completely empty with no spaces or tabs

# Solution Approach
IMPORTANT: Push back when the **architecture or design** of a solution starts getting out of hand relative to best practices — unnecessary abstraction, fragile coupling, hard-to-maintain workarounds, accidental complexity. In those cases suggest the simpler, more maintainable approach first.

Do NOT treat switching languages or frameworks (e.g. rewriting from framework X to Y, native → cross-platform, or vice versa) as "complex" by itself — a rewrite is not inherently complex and is not something to push back on. Weigh **developer experience very heavily**: fast, low-friction deploys with as few constraints as possible are worth a lot to me, often more than which language or framework is used. If a different stack gives a meaningfully better dev/deploy experience and can do the job, treat that as a legitimate, often preferable option — present the trade-offs honestly rather than defaulting to "keep what we have." When in doubt about whether a target stack covers all current functionality, ask rather than assume it can't.

# Database migrations — never silently lose data
IMPORTANT: Never generate or apply a destructive (data-losing) database migration by default. ORMs like EF Core often scaffold a `DROP TABLE` + `CREATE TABLE` (or `DROP COLUMN`) when a primary key or column changes — this discards existing rows. ALWAYS rewrite such a migration to be **data-preserving** (e.g. EF's `RenameTable` / `RenameColumn` / `AddColumn` with a default / `DropPrimaryKey` + `AddPrimaryKey`) so existing data survives. Only produce a drop-and-recreate / data-discarding migration when I have **EXPLICITLY** said "I don't care about the data" (or equivalent) for that specific change. If a migration would drop data and you don't have that explicit go-ahead, STOP and flag it — even if an earlier instruction loosely implied data loss was acceptable, re-confirm before generating it (I may have been the one who told you to drop it — double-check anyway). When unsure whether a table holds data worth preserving, check its row count first.

# New websites and webapps
When the user asks for a new website, web app, frontend, or landing page (Swedish: "hemsida", "webbsida", "webapp", "webapplikation") — always scaffold via `~/repos/webpage-deploy/` (private GitHub repo + Vercel project + Neon Postgres + Next.js, per its README). The canonical command is:

```bash
~/repos/webpage-deploy/scripts/deploy.sh <slug> "<description>" "<display-name>"
```

This applies even when the app is purely client-side or doesn't obviously need a DB — Neon is free tier and harmless, and the scaffolder is the single approved path. Don't roll a bespoke Vite/CRA/Vercel-from-scratch setup, and don't put webapps in `~/.scripts/`. After scaffolding, swap in the actual page contents and re-deploy with `vercel --prod`.

# Where new tools/scripts live
When the user asks for a new project, script, or tool, make a judgement call up front about where it should live — don't default to dropping everything in `~/.scripts/`:

- **`~/.scripts/`** — short shell/python helpers, single file, < ~50 lines, no state, no external deps. Dotfile-tracked. E.g. wifi helpers, waybar scripts.
- **`~/repos/<name>/` as its own git repo** — anything multi-file, with persisted state, configurable, or that could plausibly be packaged. ~100+ lines is a strong signal. Mention to the user when you make this call so they can `gh repo create` and wire it as a `nixpkgs` flake input later (precedents: `bt-keyboard-bridge`, `claude-code-notify`).

Surface the decision: "this is N lines / multi-component, I'm putting it in `~/repos/<name>/` instead of `~/.scripts/` — say if you'd rather keep it inline." Don't ask permission — make the call, state it, let the user redirect.

# Keep docs current autonomously
When I learn something during a task that would be useful to know next time — non-obvious infra (build servers, deploy quirks, where things live), a gotcha and its fix, a command/flow that wasn't documented, or a decision and its rationale — I write it down without being asked. Put it in the right place: project-level facts in that repo's `README.md` / `CLAUDE.md` / docs; cross-project or machine-level facts in this global `~/.claude/CLAUDE.md`; point-in-time state in auto-memory. Create the doc if it doesn't exist, and update (don't duplicate) if it does. Keep entries short and factual. Don't document what the code already makes obvious. Make the call and mention it briefly rather than asking permission.

# iOS apps — build & ship on push
My iOS apps (SwiftUI + XcodeGen `project.yml`, e.g. `notesapp-ios`, `helloworld`, `handlalistan-ios`) are **built and shipped automatically on git push** — no GitHub Actions, no Xcode Cloud, no fastlane. They push to a Mac on the LAN, not GitHub:

- The Mac is reachable by its **mDNS name `<mac>.local`** (resolves via avahi on this Linux laptop — `getent hosts <mac>.local` / `ssh martin@<mac>.local`; the literal hostname/IP are in private auto-memory). Prefer the `.local` name over the LAN IP, which is DHCP and changes. If `.local` ever fails, fall back to finding the IP (`ipconfig getifaddr en0` on the Mac) and update remotes.
- Remote `mac` = `ssh://martin@<mac>.local/Users/martin/builds/<slug>.git`. `git push mac main` (usually just `git push`, since `mac/main` is the upstream) triggers the build. (Other iOS app repos may still have the old hardcoded IP in their `mac` remote — switch them to the `.local` name too.)
- On the Mac, `~/builds/<slug>.git/hooks/post-receive` runs `~/builds/build.sh <slug>`: hard-resets `~/builds/<slug>-work` to `origin/main`, `xcodegen generate`, `xcodebuild ... -allowProvisioningUpdates build`, then `xcrun devicectl device install/launch` onto the iPhones in `<slug>.devices` (or global `~/builds/devices.conf`). Build log: `~/builds/<slug>-last-build.log`.
- **TestFlight/App Store** is a separate, explicit step (not on push): `ssh mac 'bash ~/builds/release.sh <slug>'` archives Release and uploads via an App Store Connect API key. The API key **must have the Admin role** (App Manager fails cloud signing with `FORBIDDEN_ERROR` on distribution certs); per-app `~/builds/<slug>.release` holds `ISSUER_ID`/`TEAM_ID`, and the `.p8` lives in `~/.appstoreconnect/private_keys/`. Full details in the `ios-build-server` README.
- These Mac scripts are versioned at `~/repos/ios-build-server` (GitHub `marsa099/ios-build-server`). The live copies are on the Mac; that repo is the recoverable canonical copy.
- If a push builds fine but the install step is skipped (`hoppar över <udid> — ej nåbar`), the phone was just asleep/locked. Don't re-push — run `~/builds/install-retry.sh <slug> [attempts] [delay]` on the Mac (also in the `ios-build-server` repo); it reuses the built `.app` and retries install+launch until the phone is reachable.
- **TestFlight/App Store** is a separate, explicit step (not on push): `ssh mac 'bash ~/builds/release.sh <slug>'` archives Release and uploads via an App Store Connect API key. The API key **must have the Admin role** (App Manager fails cloud signing with `FORBIDDEN_ERROR` on distribution certs); per-app `~/builds/<slug>.release` holds `ISSUER_ID`/`TEAM_ID`, and the `.p8` lives in `~/.appstoreconnect/private_keys/`. One-time per app: create the app record in App Store Connect (the App Store name must be globally unique) and add `ITSAppUsesNonExemptEncryption: false` to `project.yml`. Full details in the `ios-build-server` README.
- So I **cannot build iOS apps on this Linux laptop** (no Swift/Xcode) — to ship, push to `mac`. To verify a build, SSH to the Mac (`<mac>.local`) and read the build log.
- `~/repos/ios-app-template` is the starting point for a new iOS app — run its `./new-app.sh <slug> <AppName> [bundleId]` to scaffold the app (copies the template, replaces the `iOSTemplate` token), wire the Mac build server (bare repo + hook + `mac` remote), and push the first build. `helloworld` additionally shows a WidgetKit extension + Live Activity.

# dsqrd / slqs — updating the desktop chat clients
The Discord (`dsqrd`) and Slack (`slqs`) Wayland clients are installed system-wide via the NixOS config at `~/.config/nixos/flake.nix`, which pins them as flake inputs from `github:daphen/dsqrd` and `github:daphen/slqs` (NOT from any local checkout — pulling `~/repos/dsqrd` does nothing to the running system). To update: `update-dsqrd` (or `update-dsqrd slqs`) — a `~/.scripts/` helper that bumps the flake lock, runs `sudo nixos-rebuild switch --flake ~/.config/nixos`, then restarts the long-running daemon + Quickshell UI (a rebuild swaps the binary but won't restart already-running processes). `update-dsqrd --check` only reports whether a newer `main` exists (exit 10 = update available). Both clients run a headless daemon (`dsqrd.py` / `slqs` binary) plus a `qs -p .../share/<app>/ui` UI process; the `*-client` wrapper starts the daemon then execs the UI.

Both clients' theme hardcodes "GeistMono Nerd Font" but the nix packages don't depend on it — if it's missing, all text silently falls back to DejaVu Sans (proportional, wobbly). It's installed user-level in `~/.local/share/fonts/`; the proper home is `pkgs.nerd-fonts.geist-mono` in `fonts.packages`. A quickshell UI only picks up newly installed fonts after a UI restart.

slqs auth: no `slk` tool on this machine — write `~/.local/share/slqs/tokens/<teamID>.json` by hand with `access_token` (xoxc-…, from `localStorage.localConfig_v2` on a loaded app.slack.com client tab) and `cookie` (the HttpOnly `d` cookie value, kept URL-encoded, from DevTools cookies panel). Re-do this if the browser session that minted them is signed out.

# Ending a Claude session (qs-picker session overview)
The qs-picker Claude session overview has a lifecycle "status" column (ongoing /
done / parked / restarted / n/a). When I tell you, in a session, to end the
**whole session** — not just one task — pick the marker by what I said:

- I say it's **done/finished/complete** ("mark as done", "ok this session is
  done", "we're finished here", "this session is complete") → run:

      ~/repos/qs-picker/scripts/claude-sessions --mark-done

- I just want to **end/close the session** without calling it done ("end
  session", "close this session", "park this", "that's enough for now" — the
  work is unfinished) → run:

      ~/repos/qs-picker/scripts/claude-sessions --mark-parked

Both auto-detect the current session from the process tree, record the status
(`done` or `parked`) in the overview, and close this terminal window (so the
session goes inactive). Only run them when I clearly mean the session as a
whole — NOT for "that task is done" / "that's finished" about a single piece of
work. After running either, stop; the window closes itself.
