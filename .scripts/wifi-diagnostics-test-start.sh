#!/usr/bin/env bash
# Start (or restart) the wifi-test tmux window with 3 panes:
#   pane 1: UDP iperf3 -R 5M
#   pane 2: TCP iperf3 -R
#   pane 3: ICMP ping 1.1.1.1
# All timestamped. F12 fires a checkpoint into all 3 panes.

set -e

SESSION="${TMUX_SESSION:-projects}"
WINDOW=wifi-test

# Reset checkpoint counter
echo 0 > /tmp/wifi-cp.count

# Kill existing window if present
tmux kill-window -t "$SESSION:$WINDOW" 2>/dev/null || true

# Create new window + 3 horizontal stripes
tmux new-window -t "$SESSION:" -n "$WINDOW"
tmux split-window -t "$SESSION:$WINDOW" -v
tmux split-window -t "$SESSION:$WINDOW" -v
tmux select-layout -t "$SESSION:$WINDOW" even-vertical

# Start each test
tmux send-keys -t "$SESSION:$WINDOW.1" 'clear; echo "=== UDP iperf3 -R 5M ==="; /tmp/wifi-udp.sh' Enter
tmux send-keys -t "$SESSION:$WINDOW.2" 'clear; echo "=== TCP iperf3 -R ==="; /tmp/wifi-tcp.sh' Enter
tmux send-keys -t "$SESSION:$WINDOW.3" 'clear; echo "=== ICMP ping 1.1.1.1 ==="; /tmp/wifi-ping.sh' Enter

# Ensure F12 is bound to checkpoint
tmux bind-key -n F12 run-shell -b '/tmp/cp'

tmux select-window -t "$SESSION:$WINDOW"
echo "Started $SESSION:$WINDOW. Press F12 anywhere in tmux to fire a checkpoint."
