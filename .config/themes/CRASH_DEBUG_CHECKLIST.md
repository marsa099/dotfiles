# Theme Switch Crash Debug Checklist

## Before Testing
1. Run the debug script:
   ```bash
   ~/.config/themes/debug-crash.sh
   ```
2. Follow the prompts to switch themes when instructed

## After Crash - Check These:

### 1. Debug Output
```bash
# Find the latest debug directory
ls -la ~/.config/themes/debug-*

# View the main debug log
cat ~/.config/themes/debug-*/debug.log
```

### 2. Check for Crash Reports
```bash
# Look for new crash reports
ls -la ~/Library/Logs/DiagnosticReports/ | grep -E "ghostty|fish" | tail -10

# If found, check the crash report
cat ~/Library/Logs/DiagnosticReports/[crashfile]
```

### 3. System Console Logs
```bash
# Check Console app for errors around crash time
log show --last 5m --predicate 'process == "ghostty" OR process == "fish" OR process == "WindowServer"' | grep -E "error|crash|fault|violation"
```

### 4. Process State
```bash
# Check if processes are still running
ps aux | grep -E "ghostty|fish|theme-watcher"
```

### 5. Theme Files
```bash
# Check if theme files were corrupted
ls -la ~/.config/themes/generated/ghostty/
cat ~/.config/themes/generated/ghostty/*.theme | head -20
```

### 6. Potential Culprits to Check:
- **Race condition**: Multiple theme updates happening simultaneously
- **File access**: Theme files being read while being written
- **Signal handling**: Even though we removed USR1, check for other signals
- **Ghostty reload**: Check if Ghostty is trying to reload config during write
- **Memory/resource issue**: Too many file operations at once

### 7. Quick Recovery
If crashed, to get back to stable state:
```bash
# Kill any stuck processes
pkill -f theme-watcher
pkill -f ghostty

# Restart Ghostty manually
# Apply theme manually
~/.config/themes/theme-manager.sh auto
```

## What Changed
1. Removed USR1 signal sending to Fish processes
2. Disabled Ghostty's automatic theme switching (`theme = light:light,dark:dark`)
3. Theme-watcher now only updates files, no process signaling

## Next Debugging Steps
Based on what we find, we might need to:
1. Add file locking to prevent concurrent access
2. Add delays between file operations
3. Use atomic file writes (write to temp, then move)
4. Check Ghostty's file watching mechanism
5. Disable theme-watcher and test manual switching