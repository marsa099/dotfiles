#!/bin/bash

# Debug script to capture information before/during/after theme switch crashes
DEBUG_DIR="$HOME/.config/themes/debug-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$DEBUG_DIR"

echo "=== Theme Crash Debugging Started ===" | tee "$DEBUG_DIR/debug.log"
echo "Debug directory: $DEBUG_DIR" | tee -a "$DEBUG_DIR/debug.log"
echo "Time: $(date)" | tee -a "$DEBUG_DIR/debug.log"

# Function to capture current state
capture_state() {
    local phase=$1
    echo -e "\n=== $phase State Capture ===" | tee -a "$DEBUG_DIR/debug.log"
    
    # Process information
    echo -e "\n--- Running Processes ---" >> "$DEBUG_DIR/debug.log"
    ps aux | grep -E "fish|ghostty|theme|nvim" | grep -v grep >> "$DEBUG_DIR/debug.log" 2>&1
    
    # Current theme state
    echo -e "\n--- Current Theme ---" >> "$DEBUG_DIR/debug.log"
    defaults read -g AppleInterfaceStyle 2>&1 >> "$DEBUG_DIR/debug.log"
    
    # Copy current configs
    cp -r "$HOME/.config/themes/generated" "$DEBUG_DIR/${phase}_generated" 2>/dev/null
    
    # Ghostty config
    echo -e "\n--- Ghostty Config ---" >> "$DEBUG_DIR/debug.log"
    cat "$HOME/.config/ghostty/config" >> "$DEBUG_DIR/debug.log" 2>&1
    
    # Check file descriptors
    echo -e "\n--- Open Files (lsof) ---" >> "$DEBUG_DIR/debug.log"
    lsof -p $(pgrep -f ghostty | head -1) 2>&1 | head -50 >> "$DEBUG_DIR/debug.log"
    
    # System logs (last 50 lines)
    echo -e "\n--- System Logs ---" >> "$DEBUG_DIR/debug.log"
    log show --last 1m --predicate 'process == "ghostty" OR process == "fish"' 2>&1 | tail -50 >> "$DEBUG_DIR/debug.log"
}

# Monitor for crashes in background
monitor_crashes() {
    echo -e "\n=== Monitoring for crashes ===" | tee -a "$DEBUG_DIR/debug.log"
    
    # Watch for new crash reports
    local crash_dir="$HOME/Library/Logs/DiagnosticReports"
    local before_count=$(ls -1 "$crash_dir" 2>/dev/null | wc -l)
    
    # Monitor for 30 seconds
    for i in {1..30}; do
        sleep 1
        local after_count=$(ls -1 "$crash_dir" 2>/dev/null | wc -l)
        if [ "$after_count" -gt "$before_count" ]; then
            echo "CRASH DETECTED!" | tee -a "$DEBUG_DIR/debug.log"
            # Copy new crash reports
            find "$crash_dir" -type f -mmin -1 -exec cp {} "$DEBUG_DIR/" \; 2>/dev/null
            break
        fi
        
        # Check if ghostty is still running
        if ! pgrep -f ghostty > /dev/null; then
            echo "Ghostty process disappeared!" | tee -a "$DEBUG_DIR/debug.log"
            capture_state "POST_CRASH"
            break
        fi
    done
}

# Main debugging sequence
echo -e "\n1. Capturing PRE-switch state..." | tee -a "$DEBUG_DIR/debug.log"
capture_state "PRE"

# Save theme-watcher log
cp "$HOME/.config/themes/theme-watcher.log" "$DEBUG_DIR/theme-watcher-before.log" 2>/dev/null

echo -e "\n2. Starting crash monitor in background..." | tee -a "$DEBUG_DIR/debug.log"
monitor_crashes &
MONITOR_PID=$!

echo -e "\n3. Instructions:" | tee -a "$DEBUG_DIR/debug.log"
echo "   - Switch themes NOW (toggle system appearance)" | tee -a "$DEBUG_DIR/debug.log"
echo "   - Wait for crash or 30 seconds" | tee -a "$DEBUG_DIR/debug.log"
echo "   - Press Enter when done or if crashed" | tee -a "$DEBUG_DIR/debug.log"

read -p "Press Enter when theme switch is complete or crashed..."

# Kill monitor if still running
kill $MONITOR_PID 2>/dev/null

echo -e "\n4. Capturing POST-switch state..." | tee -a "$DEBUG_DIR/debug.log"
capture_state "POST"

# Save theme-watcher log again
cp "$HOME/.config/themes/theme-watcher.log" "$DEBUG_DIR/theme-watcher-after.log" 2>/dev/null

# Diff the logs
echo -e "\n=== Theme Watcher Log Changes ===" >> "$DEBUG_DIR/debug.log"
diff "$DEBUG_DIR/theme-watcher-before.log" "$DEBUG_DIR/theme-watcher-after.log" >> "$DEBUG_DIR/debug.log" 2>&1

echo -e "\n=== Debug Complete ===" | tee -a "$DEBUG_DIR/debug.log"
echo "Results saved to: $DEBUG_DIR" | tee -a "$DEBUG_DIR/debug.log"
echo "" | tee -a "$DEBUG_DIR/debug.log"
echo "After crash, run:" | tee -a "$DEBUG_DIR/debug.log"
echo "  cat $DEBUG_DIR/debug.log" | tee -a "$DEBUG_DIR/debug.log"
echo "  ls -la $DEBUG_DIR/" | tee -a "$DEBUG_DIR/debug.log"