#!/bin/bash

# ==========================================
# DOCKER WORKSPACE BACKUP SCRIPT (CLEAN FOLDERS)
# ==========================================

WORKSPACE="/workspace"
BACKUP_FOLDER_NAME="${BACKUP_FOLDER_NAME:-.backup}"
BACKUP_DIR="${WORKSPACE}/${BACKUP_FOLDER_NAME}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/backup_${TIMESTAMP}.tar.gz"
COPIES_TO_KEEP="${COPIES_TO_KEEP:-7}"

execute_backup() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Starting backup process..."

    # 1. Ensure dynamic backup folder exists
    mkdir -p "$BACKUP_DIR"

    # 2. Build the exclusion arguments for the tar command
    TAR_EXCLUDES=""
    for item in $EXCLUDES; do
        TAR_EXCLUDES="$TAR_EXCLUDES --exclude=$item"
    done
    TAR_EXCLUDES="$TAR_EXCLUDES --exclude=${BACKUP_FOLDER_NAME}"

    # 3. Create the compressed archive using clean workspace matching
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Archiving workspace folders..."
    
    # Enable dotglob to catch hidden files like .env if they exist
    shopt -s dotglob
    
    # Execute tar from workspace directory directly against target folders
    cd "$WORKSPACE" || exit 1
    tar -czf "$BACKUP_FILE" $TAR_EXCLUDES *

    if [ $? -eq 0 ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: Backup saved to $BACKUP_FILE"
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: Backup failed!"
        exit 1
    fi

    # 4. Enforce retention policy
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Enforcing retention policy: keeping last $COPIES_TO_KEEP copies."
    cd "$BACKUP_DIR" || exit
    ls -1tr backup_*.tar.gz 2>/dev/null | head -n -"$COPIES_TO_KEEP" | xargs -I {} rm -f {}

    # 5. Fix permissions for host user
    if [ -n "$PUID" ] && [ -n "$PGID" ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Fixing permissions to $PUID:$PGID..."
        chown -R "${PUID}:${PGID}" "$BACKUP_DIR"
    fi

    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Backup process complete."
}

if [ "$1" == "-f" ] || [ "$1" == "--force" ]; then
    echo "[INFO] Manual 'run now' key detected."
    execute_backup
else
    execute_backup
fi
