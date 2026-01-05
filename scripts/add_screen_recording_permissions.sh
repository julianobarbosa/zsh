#!/bin/bash

# Script to add applications to Screen & System Audio Recording permissions
# Requires: Full Disk Access for Terminal/iTerm or run with sudo

# Application paths
BARTENDER_PATH="/Applications/Bartender 5.app"
TEAMS_PATH="/Applications/Microsoft Teams.app"

# Get bundle identifiers
get_bundle_id() {
    local app_path="$1"
    /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$app_path/Contents/Info.plist" 2>/dev/null
}

echo "Getting bundle identifiers..."
BARTENDER_ID=$(get_bundle_id "$BARTENDER_PATH")
TEAMS_ID=$(get_bundle_id "$TEAMS_PATH")

echo "Bartender Bundle ID: $BARTENDER_ID"
echo "Microsoft Teams Bundle ID: $TEAMS_ID"

# TCC database path (user-level)
TCC_DB="$HOME/Library/Application Support/com.apple.TCC/TCC.db"

# Function to add screen recording permission
add_screen_recording_permission() {
    local bundle_id="$1"
    local app_path="$2"

    echo "Adding screen recording permission for: $bundle_id"

    # For macOS 13+ (Ventura and later)
    sqlite3 "$TCC_DB" "INSERT or REPLACE INTO access VALUES('kTCCServiceScreenCapture','$bundle_id',0,2,4,1,NULL,NULL,0,'UNUSED',NULL,0,1687449600);"

    # For macOS 12 and earlier, use this instead:
    # sqlite3 "$TCC_DB" "INSERT or REPLACE INTO access VALUES('kTCCServiceScreenCapture','$bundle_id',0,2,0,1,NULL,NULL,NULL,'UNUSED',NULL,0,1687449600);"
}

# Check if apps exist
if [ ! -d "$BARTENDER_PATH" ]; then
    echo "Warning: Bartender 5.app not found at $BARTENDER_PATH"
else
    add_screen_recording_permission "$BARTENDER_ID" "$BARTENDER_PATH"
fi

if [ ! -d "$TEAMS_PATH" ]; then
    echo "Warning: Microsoft Teams.app not found at $TEAMS_PATH"
else
    add_screen_recording_permission "$TEAMS_ID" "$TEAMS_PATH"
fi

echo ""
echo "Done! You may need to:"
echo "1. Restart the applications"
echo "2. Log out and log back in, or restart your Mac"
echo "3. Grant Terminal/iTerm Full Disk Access in System Settings > Privacy & Security"
echo ""
echo "Note: On macOS 13+, you might need to disable SIP or use a configuration profile instead."
