# waybar-devops

Waybar custom module that shows Azure DevOps deployment status for the git project in your focused terminal.

## Output

The module shows one of three things, in priority order:

1. **Active build/release lifecycle** — when a CI build is in progress, the script tracks it through completion → triggered release → release outcome:
   ```
   sis.portal.api: Building (3/6: Test) - 1m 23s
   sis.portal.api: ✓ Build Succeeded - 4m 12s
   sis.portal.api: Releasing 1.10.0 to Test - 38s
   sis.portal.api: ✓ Released 1.10.0 to Test - 2m 5s
   sis.portal.api: ✗ Build Failed (Test) - 1m 47s
   ```
   Lifecycle state persists for 60s after completion and **across focus changes** — switching to another window won't drop the indicator.
2. **Latest succeeded deployment per env** — when nothing's building:
   ```
   D: main    T: 1.10.0    P: 1.9.3
   ```
   Branch prefixes are stripped (`release/`, `feature/`, `bugfix/`, `hotfix/`). A `⚠` is appended if any deployed release branch (e.g. `1.10.0`) isn't merged to `origin/main`.
3. **Empty / faded** — when not in an Azure DevOps repo, or no matching release definition. Last output stays visible for 10s with `class: stale` (CSS `opacity: 0.5`) before disappearing.

## How it works

1. Detects the focused terminal's CWD (tmux pane via process tree walk, or bare terminal via niri IPC + `/proc`)
2. Checks if it's a git repo with an Azure DevOps remote, parses org/project/repo from the URL
3. Resolves the repo GUID, finds build definitions targeting that repo, then matches release definitions whose artifact references one of those build defs
4. **Lifecycle tracking** — if a build is in progress, saves it to `build_lifecycle.json` and walks the state machine: `building → build_succeeded → releasing → release_done` (or `build_failed`). Release matching pairs the in-progress deployment to the build via artifact id.
5. **Fallback** — if no active lifecycle, queries the latest *succeeded* deployment per environment for display
6. Outputs waybar JSON with `class` reflecting state: `building | build-succeeded | build-failed | releasing | release-succeeded | release-failed | active | stale | empty | pat-error`

## Limitations

- **Releases without a CI build are not tracked.** The lifecycle state machine only enters `releasing` by chaining off a build it observed (matching the deployment's artifact to the build id). Pipelines where the release pulls the repo as a **Git artifact** (e.g. classic release pipelines for Bicep/IaC, like `SIS.Portal.IaC`) have no parent build to latch onto, so an in-progress deploy is invisible — the module keeps showing the last *succeeded* deployment instead. Fixing this requires a separate path that polls `release/deployments?definitionId=<def_id>&deploymentStatus=inProgress` per discovered env, independent of `get_active_build`.
- **One environment per name across all release definitions.** `discover_environments` deduplicates by env name, preferring the def where it's the final stage. If two release defs both have a `Dev` stage and neither is final, the lower def id wins.
- **Exclude list is per repo, hardcoded.** Edit `EXCLUDE_DEFS` near the top of the script to skip specific release definition IDs (e.g. `EXCLUDE_DEFS["SIS.CommitteePortal"]="11"`).

## Auth

PAT stored in the system keyring via `secret-tool`:

```sh
# Store/update PAT
secret-tool store --label='Azure DevOps PAT (waybar)' service azure-devops type waybar

# Verify it's stored
secret-tool lookup service azure-devops type waybar
```

The PAT needs `Build (Read)` and `Release (Read)` scopes.

PAT validity is checked against the API and cached for 5 minutes. If expired, waybar shows "DevOps: PAT Expired" and stops making API calls until the cache expires or a new PAT is stored.

## Requirements

- `secret-tool` (libsecret) for PAT storage
- `jq`
- `niri` (for bare terminal CWD detection)
- `tmux` (optional, for tmux pane CWD detection)
- Git repos with Azure DevOps SSH or HTTPS remotes

## Waybar config

```jsonc
"custom/devops": {
    "exec": "~/.scripts/waybar-devops/waybar-devops",
    "return-type": "json",
    "interval": 5,
    "tooltip": true
}
```

## Debugging

```sh
# Watch live logs
tail -f ~/.cache/waybar-devops/waybar-devops.log

# Run manually
~/.scripts/waybar-devops/waybar-devops

# Clear cache
rm -rf ~/.cache/waybar-devops/
```

## Caching

The script runs every 5 seconds (waybar interval) but caches API responses to avoid unnecessary calls. Most runs only read the CWD and cached files from disk.

All cache files are stored in `~/.cache/waybar-devops/`:

| File | TTL | Purpose |
|------|-----|---------|
| `pat_status` | 5 min | PAT validity (valid/invalid). Auto-invalidates when PAT changes. |
| `discovery_*.json` | 1 hour | Release definition + environment IDs. |
| `repoguid_*.txt` | 1 hour | Git repository GUID for build queries. |
| `deploy_*.json` | 60s | Latest deployed branch per environment. |
| `build_*.json` | 10s | Active build status. |
| `timeline_*.json` | 10s | Build stage progress. |
| `state.json` | 10s | Last output, used to fade out when leaving a git repo. |
| `build_lifecycle.json` | 60s | Build lifecycle state machine (persists across focus changes). |
