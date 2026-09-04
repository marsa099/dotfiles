# Git commande
## Commit
When using git commit, keep the message short and descriptive. Syntax for commit messages should be "Fixes bug #1234". instead of "Implemented a fix for bug #1234".

IMPORTANT: Always use English for commit messages, never Swedish or other languages.

IMPORTANT: Do NOT add Claude Code attribution or co-authored-by lines to commit messages. Keep commits clean and concise.

## Always commit and push to main after a finished round
IMPORTANT: When a round of work is done — a feature, a fix, whatever I just asked for — commit it and get it onto `main` WITHOUT being asked. Never leave finished work sitting uncommitted in a worktree waiting for me to request the push. Concretely: commit in the worktree, fast-forward merge into `main`, `git push origin main`. If a session has several rounds, do this at the end of EACH round, not once at the very end — I should never have to ask "did you push?". The only reason to hold off is work that is knowingly broken or half-finished; then say so plainly instead of pushing. This is standing authorization for the commit + merge + push, and it composes with the worktree rule below (worktree first, merge and push at the end of the round).

# Git worktrees — always start one before making code changes
IMPORTANT: In EVERY repo, at the start of ANY session that is going to make code changes, create and switch into a separate git worktree (the EnterWorktree tool) BEFORE editing anything — without Martin having to ask. He often runs multiple parallel Claude sessions in the same repo, and sessions working directly on the shared checkout collide (branch switches, dirty trees, conflicting edits). This instruction is standing authorization for EnterWorktree in all repos. Read-only sessions (questions, investigation, no edits) don't need one — but the moment code changes are on the table, enter the worktree first. Finish by merging/pushing per the repo's normal workflow.

# Status-polling loops — parse properly and fail loudly
When writing a loop that polls a status field (build/deploy/CI/queue), do NOT extract the value with brittle grep/sed chains — parse the JSON with `jq` or `node -e` (both available here). Test the extraction ONCE against real output before starting the loop. And make the loop fail loudly: an empty/unparseable status must break out (or print an obvious error), never be silently treated as "still waiting" — otherwise the loop spins blind long after the thing finished. (Learned 2026-07-22: a `grep -o '[A-Z_]*$'` chain always matched empty because the JSON value's closing quote sat at end-of-line, so an EAS build monitor polled for an hour after the build was done.)

# Archiving cc web (claude.ai/code) sessions
There is NO official CLI command or API to archive a claude.ai/code session (verified 2026-07-23; web-UI only). Use `~/.scripts/archive-cc-session <session_id|name>` — it drives a headless Helium over CDP using `~/.config/helium-C-Private` (a copy of the Private profile, so Martin's live browser is never locked out): opens claude.ai/code, finds the session row (`session_...` args match `data-row-key="code:session_<id>"`, the id from the session's claude.ai/code URL; other args match the displayed name), clicks "More options" → Archive, verifies against a fresh reload. Headless claude.ai needs the desktop user-agent + `--disable-blink-features=AutomationControlled` flags the script sets, or Cloudflare blocks it. If claude.ai login in the copy ever breaks: `rsync -a --delete --exclude='Singleton*' ~/.config/helium-Private/ ~/.config/helium-C-Private/`. The bye skill runs this automatically for remotely-controllable sessions.

# sudo on this machine (NixOS)
`sudo nixos-rebuild` is **passwordless** for martin (NOPASSWD rule scoped to `/run/current-system/sw/bin/nixos-rebuild` in configuration.nix) — set up precisely so agent-driven rebuilds don't block. So `update-dsqrd` and any `nixos-rebuild switch` run fully headless: just run them directly, no terminal popup or user hand-off needed. Do NOT probe with `sudo -n true` — the rule is command-scoped, so that probe fails and misleads; probe with `sudo -n nixos-rebuild list-generations` if needed. All other sudo commands still need a password.

# Vercel CLI on this machine (NixOS)
The Vercel CLI is not (and can't easily be) installed globally — `npm i -g` fails on NixOS and nixpkgs has no `vercel` package (only the unrelated `vercel-pkg`). Use `npx -y vercel <cmd>` instead; it's already authenticated (token in home dir, account `marsa099`), so no login step is needed.

# Code Style Rules
IMPORTANT: NEVER add trailing whitespaces after lines or whitespace-only lines. This applies to ALL projects FOREVER. When writing or editing code:
- No trailing whitespaces at the end of lines
- No lines that contain only whitespace characters
- Empty lines should be completely empty with no spaces or tabs

# Global npm CLIs on this machine (NixOS)
`npm i -g` fails (prefix points into the read-only nix store). For npm CLIs worth a real install (not just `npx -y`): `npm install -g --prefix ~/.npm-global <pkg>`, then a 2-line exec wrapper in `~/.scripts/<name>` pointing at `~/.npm-global/bin/<name>`.

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
The Discord (`dsqrd`) and Slack (`slqs`) Wayland clients are installed system-wide via the NixOS config at `~/.config/nixos/flake.nix`, which pins them as flake inputs (NOT from any local checkout — pulling `~/repos/dsqrd` does nothing to the running system). dsqrd and slqs **track daphen directly** (`github:daphen/dsqrd`, `github:daphen/slqs`; dsqrd went back to upstream 2026-08-10, and its local checkout stopped being a fork 2026-09-03). **mlqs is a fork again** — the flake pins `github:marsa099/mlqs` and `~/repos/mlqs` is the live checkout (`origin`=marsa099, `upstream`=daphen). To update: `update-dsqrd` (or `update-dsqrd slqs` / `mlqs`) — a `~/.scripts/` helper that bumps the flake lock, runs `sudo nixos-rebuild switch --flake ~/.config/nixos`, then restarts the long-running daemon + Quickshell UI (a rebuild swaps the binary but won't restart already-running processes). dsqrd/slqs are single-leg; **mlqs is two-legged** (re-enabled 2026-09-02): U first merges `upstream/main` into the fork's main and pushes it, then bumps the lock and rebuilds. Two things must both hold or the badge sticks on forever: (1) the mlqs `case` in `update-dsqrd`'s `IS_FORK` block, and (2) the `-X main.updateRepo=marsa099/mlqs` + `-X main.upstreamRepo=daphen/mlqs` ldflags in the fork's `flake.nix` — without those the daemon uses its source default (`updateRepo=daphen/mlqs`, no upstream) and takes the single-leg plain-SHA path, and a fork's main can never equal daphen's main. Both were silently lost once when a PR series landed on `origin/main` — re-check them after any upstream reconcile. Gotcha: after editing a flake input's URL, the script reports "up to date" without rebuilding — `nix flake metadata` re-locks the changed input on the fly — so rebuild manually after a repo repoint. The in-app "update available" badge is the daemon polling its `updateRepo`/`upstreamRepo` main SHAs (via the GitHub compare API, so a fork *ahead* of upstream is not flagged). `update-dsqrd --check` reports it (exit 10 = update available). Both clients run a headless daemon (`dsqrd.py` / `slqs` binary) plus a `qs -p .../share/<app>/ui` UI process; the `*-client` wrapper starts the daemon then execs the UI.

**There is no dsqrd fork any more (as of 2026-09-03).** `~/repos/dsqrd` is a plain upstream checkout: `origin` = `daphen/dsqrd`, `main` tracks it, nothing local on top. The old fork commits are archived on the local branch `archive/fork-main` and still on `fork/main` (`marsa099/dsqrd`) if ever needed; they were all obsolete — daphen shipped his own `open` command, merged the launcher `pgrep` fix as PR #11, and the `DSQRD_*_REPO` update-badge plumbing only ever mattered when building *from* a fork. So `~/repos/dsqrd` can be hard-reset to `origin/main` freely.

`dsqrd-cli` (used by the `dsqrd` skill) is **not** packaged and deliberately lives **outside** the repo, at `~/.scripts/dsqrd-cli` — that is what let the fork die. It is a single stdlib-only Python file on PATH (call it as plain `dsqrd-cli`), talks to whatever daemon is up over `$XDG_RUNTIME_DIR/dsqrd.sock`, and every protocol command it uses (`history`, `send`, `open`, `summarize`) exists upstream. Upstream issue #8 asks for it; if daphen ever merges it, delete the local copy. Gotcha for *you*: never `pkill -f 'share/dsqrd/dsqrd\.py'` from an inline `bash -c` — the pattern matches your own shell's command line and kills the session.

Media viewing (`v`): on 2026-09-03 daphen replaced the old 150-line `media-viewer.sh` with a stripped ~25-line one, in three quick commits — `6fa4907` (exec'd a `mediactl view` binary that exists only on his machine, which broke `v` here outright), `7fc5aee` (added an inline imv/mpv fallback), then `8cae084` (**dropped the `mediactl` lookup entirely**; do not bother packaging or writing a `mediactl` — that hook no longer exists). The shipped script now works everywhere but is much dumber than what it replaced: no theme-matched imv background (black hole in the floating window), no output-relative window sizing or size-to-image, `mix` collapsed into `video` (loses `h`/`l` stepping and `image-display-duration=inf`), and no URL content-type sniffing or `.gifv`→`.gif` rewrite, so giphy/tenor embeds open in the browser instead of imv.

The supported extension point is an **env var**: `8cae084` changed the launcher to `export SLK_MEDIA_VIEWER="''${SLK_MEDIA_VIEWER:-<pkg>/share/dsqrd/media-viewer.sh}"`, so a value already in the environment wins. **This is done as of 2026-09-04**: the pre-`6fa4907` script is restored at **`~/.scripts/dsqrd-media-viewer.sh`** and `environment.sessionVariables.SLK_MEDIA_VIEWER` points at it in `~/.config/nixos/configuration.nix`. Local changes vs upstream's old version: **two size knobs near the top** — `win_w`/`win_h` (window cap, raised to **90%/90%** of the focused output, was 75/85) and `max_upscale_pct` (**250**, i.e. an image smaller than the cap is blown up to 2.5x native to fill the window). The second one is usually the one that matters: upstream only ever *shrank* to fit, so a 1920x1080 screenshot on a 3072x1728@1.25 output opened at its native 1536x864 logical — half the screen — no matter how large the cap was. imv 5's default scaling mode is `full` (scales up and down to fit the window), and no `~/.config/imv/config` exists here, so the window size the script asks for is exactly what decides apparent size. Also: `colors.json` looked up in `~/repos/themes-generator/` (upstream assumed `~/.config/themes/`, which does not exist here), and the debug log moved to `~/.cache/dsqrd-media-viewer.log` with `|| true` so an unwritable log can't abort viewing under `set -e`. Images smaller than the cap still open at their own size (physical px ÷ output scale). It needs `imv`, `imv-msg`, `mpv`, `jq`, `curl`, `niri msg`, and ImageMagick `identify` on PATH (all present system-wide). The same var is read by the QML UI (`ui/Backend.qml`), whose own fallback path is `~/.config/qs-chat-clients/media-viewer.sh` — but the launcher always sets the var, so that fallback never fires in practice. `environment.sessionVariables` only reaches processes started after a **re-login**, so after changing it, log out/in (or start the client with the var set explicitly) before testing. Test the script headlessly by putting stub `imv`/`mpv`/`setsid` scripts early on PATH that append `"$*"` to a file — `view_in_imv` redirects to `/dev/null`, so a stub that echoes shows nothing.

The updater family's upstream-merge leg refuses on a dirty fork checkout (`git status --porcelain`) — untracked files count, and a Claude worktree under `<repo>/.claude/worktrees/` used to trip it (updater printed "uncommitted changes — skipping the upstream merge" and left the upstream leg forever pending). Fixed 2026-07-22 by adding `**/.claude/worktrees/` to the global gitignore (`~/.config/git/ignore`); if an updater ever skips the merge leg again, check for real dirt in the fork checkout.

Both clients' theme hardcodes "GeistMono Nerd Font" but the nix packages don't depend on it — if it's missing, all text silently falls back to DejaVu Sans (proportional, wobbly). It's installed user-level in `~/.local/share/fonts/`; the proper home is `pkgs.nerd-fonts.geist-mono` in `fonts.packages`. A quickshell UI only picks up newly installed fonts after a UI restart.

slqs auth: no `slk` tool on this machine — write `~/.local/share/slqs/tokens/<teamID>.json` by hand with `access_token` (xoxc-…, from `localStorage.localConfig_v2` on a loaded app.slack.com client tab) and `cookie` (the HttpOnly `d` cookie value, kept URL-encoded, from DevTools cookies panel). Re-do this if the browser session that minted them is signed out.

# Proxmox home server (sundby-pve) — Immich + NVIDIA GPU transcoding
Host `sundby-pve` at 192.168.1.203 (PVE 9 / Debian trixie, kernel 6.17). GTX 1070 (Pascal) used for Immich video transcoding. Immich runs in **Docker inside unprivileged LXC 100 `media`** (`/docker/immich`, nesting=1); VM 101 `servarr` is unrelated.

Set up 2026-08-03. The non-obvious parts:
- **Driver must be the 580 branch** (580.178.04 as of now, from `download.nvidia.com/XFree86/Linux-x86_64/`). Debian trixie's `nvidia-driver` is 550 and its DKMS build **fails on kernel 6.16+**; the 595 production branch **dropped Pascal**. So 580 is the only window — install via the `.run` installer with `--dkms --silent` on the host, and the *same version* inside the LXC with `--no-kernel-module --silent` (userspace libs only; ABI must match exactly or you get "Driver/library version mismatch").
- Host needs `/etc/modules-load.d/nvidia.conf` (nvidia, nvidia_uvm) + a udev rule to create/chmod the device nodes at boot, else they vanish after reboot.
- LXC access = four `dev0`–`dev3` lines in `/etc/pve/lxc/100.conf` for `/dev/nvidia0`, `nvidiactl`, `nvidia-uvm`, `nvidia-uvm-tools`, all `mode=0666` (unprivileged container).
- Inside the LXC: nvidia-container-toolkit **with `nvidia-ctk config --set nvidia-container-cli.no-cgroups --in-place`** — mandatory, an unprivileged LXC can't write cgroup device rules.
- `docker exec immich_server nvidia-smi` **fails by design** — Immich's nvenc block requests gpu/compute/video capabilities, not `utility`. Verify with `ls /usr/lib/x86_64-linux-gnu/libnvidia-encode*` instead, or `nvidia-smi dmon -s u` on the host (its first column is the GPU *index*, not a utilization number — the ones that matter are `enc`/`dec`).
- Immich compose: `hwaccel.transcoding.yml` must be downloaded next to `docker-compose.yml`, then the `extends:` block under `immich-server` uncommented with `service: nvenc`.
- Transcoding settings tuned for 4K60 drone footage (DJI Mini 4 Pro): policy `bitrate`, maxBitrate `50M`, targetResolution `original`, h264, preset `slow`, accel `nvenc` + hardware decoding. Defaults would have downscaled everything to 720p. Originals are never touched — the transcode is a separate file in `encoded-video/`, and downloads always return the original, so Immich is safe as an archive.
- **Real-time transcoding (v3.0+, HLS, web app only) was tried and deliberately turned off.** The ceiling is NVDEC, not NVENC: one 4K60 HEVC stream pushes `dec` to 90%+, and decode is always of the *source*, so even a viewer on the 480p rung costs a full 4K60 decode — i.e. ~1 concurrent realtime 4K viewer, hit long before the 3–5 NVENC session limit. Pre-generated transcodes are served as static HTTP with zero GPU involvement and scale to dozens of viewers. Downside of offline-only: a single rendition, no adaptive fallback, so 50M assumes LAN/good broadband.
- Other 1070 limits: no AV1, and D-Log M footage looks flat regardless (Immich has no LUT support) — shoot Normal or HLG.

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
