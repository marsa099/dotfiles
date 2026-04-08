# waybar-devops

Waybar custom module that shows Azure DevOps deployment status for the git project in your focused terminal.

## Output

```
● Test: test  ● Prod: 1.10.0
```

Shows the currently deployed branch per environment, with common prefixes stripped (`release/`, `feature/`, `bugfix/`, `hotfix/`).

## How it works

1. Detects the focused terminal's CWD (tmux pane via process tree walk, or bare terminal via niri IPC + `/proc`)
2. Checks if it's a git repo with an Azure DevOps remote
3. Parses the remote URL to extract org/project/repo
4. Discovers the matching release definition via the Azure DevOps API (build def name matches repo name)
5. Queries the latest successful deployment per environment
6. Outputs waybar JSON (`{"text": "...", "tooltip": "...", "class": "active|stale|empty"}`)

When you leave a git repo, the module fades (CSS `opacity: 0.5`) and disappears after 10 seconds.

## Auth

PAT stored in the system keyring via `secret-tool`:

```sh
# Store/update PAT
secret-tool store --label='Azure DevOps PAT' service azure-devops type pat

# Verify it's stored
secret-tool lookup service azure-devops type pat
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
