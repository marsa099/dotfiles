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

## Requirements

- `az` CLI logged in (`az login`)
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
| `discovery_*.json` | 1 hour | Release definition + environment IDs. Rarely changes so only re-fetched once per hour. |
| `deploy_*.json` | 60 seconds | Latest deployed branch per environment. Re-fetched every 60s to pick up new deployments. |
| `state.json` | 10 seconds | Last output, used to fade out the module when leaving a git repo. |

In practice: ~50 out of 60 runs are cache-only (no API calls), 1 in 12 fetches fresh deployment data, and 1 in 720 re-discovers the pipeline structure.
