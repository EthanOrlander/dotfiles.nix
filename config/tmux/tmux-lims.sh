#!/bin/bash

# LIMS tmux session setup script
# Creates a session with nvim on the left and multiple panes on the right

SESSION_NAME="lims"
WORK_DIR="/Users/Ethan.Orlander/code/lims"

# Check if session already exists
tmux has-session -t $SESSION_NAME 2>/dev/null

if [ $? == 0 ]; then
    echo "Session '$SESSION_NAME' already exists. Attaching..."
    tmux attach-session -t $SESSION_NAME
    exit 0
fi

# Create new session with first window named "lims"
tmux new-session -d -s $SESSION_NAME -n lims -c $WORK_DIR

# Split vertically (create right side)
tmux split-window -h -t $SESSION_NAME:1.0 -c $WORK_DIR

# Split vertically for dev
tmux split-window -v -t $SESSION_NAME:1.1 -c $WORK_DIR

# Split vertically below the dev/btop row for claude
tmux split-window -v -t $SESSION_NAME:1.2 -c $WORK_DIR

# Split one more time for empty terminal
tmux split-window -h -t $SESSION_NAME:1.1 -c $WORK_DIR

# Start nvim in the first pane
tmux send-keys -t $SESSION_NAME:1.0 "nvim" C-m

# Split the right side horizontally for dev
tmux send-keys -t $SESSION_NAME:1.1 "dev" C-m

tmux send-keys -t $SESSION_NAME:1.2 "btop" C-m

tmux send-keys -t $SESSION_NAME:1.3 "claude" C-m


# Select the nvim pane to start
tmux select-pane -t $SESSION_NAME:1.0

# Attach to the session
tmux attach-session -t $SESSION_NAME
