#!/bin/bash
# morning-work.sh
# Launches and assigns apps to AeroSpace workspaces for the start of the day.
#
# Workspace layout:
#   1 - Browser (Chrome)
#   2 - Editor (VS Code)
#   3 - Terminal
#   4 - Notes (Obsidian)
 
open_and_assign() {
    local app="$1"
    local workspace="$2"
 
    open -a "$app"
 
    # Give the app a moment to launch / come to the foreground
    sleep 1.5
 
    aerospace move-node-to-workspace "$workspace"
}
 
# Launch apps and place them
open_and_assign "Google Chrome" 1
open_and_assign "Visual Studio Code" 2
open_and_assign "Terminal" 3
open_and_assign "Obsidian" 4
 
# Land on the browser to start the day
aerospace workspace 1
 
echo "Morning layout ready."
