#!/bin/bash

# ==========================================
# DOCKER WORKSPACE RESTORATION SCRIPT
# ==========================================

WORKSPACE="/workspace"
BACKUP_FOLDER_NAME="${BACKUP_FOLDER_NAME:-.backup}"
BACKUP_DIR="${WORKSPACE}/${BACKUP_FOLDER_NAME}"

echo "=========================================="
echo "⚡ DOCKER WORKSPACE DISASTER RECOVERY ⚡"
echo "=========================================="

# 1. Verify backup directory exists and has files
if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR"/*.tar.gz 2>/dev/null)" ]; then
    echo "❌ ERROR: No backup files (.tar.gz) found in $BACKUP_DIR"
    exit 1
fi

# 2. List available backups chronologically (newest at the bottom)
echo "Available backups:"
echo "------------------------------------------"
select FILE in $(ls -1tr "$BACKUP_DIR"/*.tar.gz); do
    if [ -n "$FILE" ]; then
        BACKUP_TARGET="$FILE"
        break
    else
        echo "❌ Invalid selection. Please choose a valid number."
    fi
done

echo "------------------------------------------"
echo "⚠️  CRITICAL WARNING ⚠️"
echo "You selected: $(basename "$BACKUP_TARGET")"
echo "This will wipe all active contents in '$WORKSPACE' (except backup data)!"
read -p "Are you absolutely sure you want to proceed? (type 'yes' to confirm): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Restoration aborted by user."
    exit 0
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Starting system restoration..."

# 3. Safely purge active workspace directories to prevent file ghosting
# Loops over all contents and removes everything EXCEPT critical configuration items
echo "Cleaning active workspace directories..."
shopt -s dotglob
for item in "$WORKSPACE"/*; do
    name=$(basename "$item")
    # NEVER delete the backup archive folder, the script directory, or caddy config
    if [ "$name" != "$BACKUP_FOLDER_NAME" ] && [ "$name" != "bscript" ] && [ "$name" != "syncthing_config" ]; then
        rm -rf "$item"
    fi
done

# 4. Extract target backup archive back into the workspace root
echo "Extracting archive content..."
tar -xzf "$BACKUP_TARGET" -C "$WORKSPACE"

if [ $? -eq 0 ]; then
    echo "✅ SUCCESS: Workspace files extracted perfectly."
else
    echo "❌ ERROR: Extraction failed! Your archive might be corrupted."
    exit 1
fi

# 5. Restore correct host system file ownership constraints
if [ -n "$PUID" ] && [ -n "$PGID" ]; then
    echo "Re-applying host system permissions ($PUID:$PGID)..."
    chown -R "${PUID}:${PGID}" "$WORKSPACE"
fi

echo "=========================================="
echo "🎉 DISASTER RECOVERY COMPLETE!"
echo "Run 'docker compose up -d' to restart your app stack."
echo "=========================================="
