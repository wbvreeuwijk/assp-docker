#!/bin/sh

CFG_LOCAL="/usr/share/assp/assp.cfg"
CFG_VOLUME="/etc/assp/assp.cfg"

echo "ASSP Configuration Watcher daemon started."

# Start background file-watcher loop
while true; do
    if [ -f "$CFG_LOCAL" ] && [ -f "$CFG_VOLUME" ]; then
        if [ "$CFG_LOCAL" -nt "$CFG_VOLUME" ]; then
            echo "Local configuration is newer. Syncing to volume..."
            cp -p "$CFG_LOCAL" "$CFG_VOLUME"
            chown assp:assp "$CFG_VOLUME" 2>/dev/null || true
        elif [ "$CFG_VOLUME" -nt "$CFG_LOCAL" ]; then
            echo "Volume configuration is newer. Syncing to local..."
            cp -p "$CFG_VOLUME" "$CFG_LOCAL"
            chown assp:assp "$CFG_LOCAL" 2>/dev/null || true
        fi
    elif [ -f "$CFG_LOCAL" ] && [ ! -f "$CFG_VOLUME" ]; then
        echo "Local config found but volume config missing. Initializing volume..."
        cp -p "$CFG_LOCAL" "$CFG_VOLUME"
        chown assp:assp "$CFG_VOLUME" 2>/dev/null || true
    elif [ -f "$CFG_VOLUME" ] && [ ! -f "$CFG_LOCAL" ]; then
        echo "Volume config found but local config missing. Restoring local..."
        cp -p "$CFG_VOLUME" "$CFG_LOCAL"
        chown assp:assp "$CFG_LOCAL" 2>/dev/null || true
    fi
    sleep 2
done
