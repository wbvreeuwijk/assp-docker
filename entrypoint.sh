#!/bin/sh

CFG_LOCAL="/usr/share/assp/assp.cfg"
CFG_VOLUME="/etc/assp/assp.cfg"

echo "Running ASSP entrypoint initialization..."

# Check if /etc/assp volume mount exists
if [ -d "/etc/assp" ]; then
    # If the volume file exists, it is our source of truth. Copy it to local.
    if [ -f "$CFG_VOLUME" ]; then
        echo "Found existing config on host volume. Synchronizing to local..."
        rm -f "$CFG_LOCAL"
        cp -p "$CFG_VOLUME" "$CFG_LOCAL"
    elif [ -f "$CFG_LOCAL" ]; then
        # Local exists (or is a symlink/placeholder from earlier config) but volume does not.
        # If it's a symlink, resolve it.
        if [ -L "$CFG_LOCAL" ]; then
            TARGET=$(readlink "$CFG_LOCAL")
            if [ -f "$TARGET" ]; then
                echo "Initializing volume config from resolved symlink target..."
                cp -p "$TARGET" "$CFG_VOLUME"
            fi
            rm -f "$CFG_LOCAL"
        else
            echo "Initializing volume config from local config..."
            cp -p "$CFG_LOCAL" "$CFG_VOLUME"
        fi
        
        # Ensure local is now a regular file and match the volume config
        if [ -f "$CFG_VOLUME" ]; then
            cp -p "$CFG_VOLUME" "$CFG_LOCAL"
        fi
    fi

    # Ensure permissions are correct on both local and volume files
    chown -R assp:assp /etc/assp /usr/share/assp 2>/dev/null || true
else
    echo "Warning: /etc/assp directory not found. Starting normally."
fi

# Hand off to supervisord
echo "Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
