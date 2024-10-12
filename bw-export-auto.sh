#!/bin/bash

# Configuration
EXPORT_DIR="."
RETENTION_DAYS=10
RCLONE_REMOTE="gdrive:bitwarden-backups" # edit this to your rclone remote and path
BW_SESSION="BW_SESSION" # get it from `bw unlock --raw`

# Date and filename setup
CURRENT_DATE=$(date '+%Y-%m-%d_%H-%M-%S')
EXPORT_FILE="${EXPORT_DIR}/bw-encrypted-vault_${CURRENT_DATE}.json"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Log start of the process
log_message "Starting Bitwarden export and upload."

# Export the Bitwarden vault
log_message "Exporting Bitwarden vault to $EXPORT_FILE."
bw export --format encrypted_json --output "$EXPORT_FILE"  --session $BW_SESSION # session is used to export without password prompt
if [ $? -ne 0 ]; then
    log_message "Failed to export Bitwarden vault."
    exit 1
fi

# Upload the file to Google Drive
log_message "Uploading $EXPORT_FILE to Google Drive."
rclone copy "$EXPORT_FILE" "$RCLONE_REMOTE"
rclone copyto "$EXPORT_FILE" "$RCLONE_REMOTE/bw-encrypted-vault-latest.json" # keep a copy of the latest export, if delete older then rentention days logic have bug and delete lastest dates. this will atleast keep newest copy save 
# also it will help to find latest backup if we ever need to restore from backup, no need to read dates


if [ $? -ne 0 ]; then
    log_message "Failed to upload $EXPORT_FILE to Google Drive."
    exit 1
fi

# Optional: Clean up the exported file
log_message "Cleaning up exported file."
rm "$EXPORT_FILE"

# Remove old backups from Google Drive, keeping only the last 10 days
log_message "Removing backups older than $RETENTION_DAYS days from Google Drive."
rclone lsf --files-only "$RCLONE_REMOTE" | while read -r file; do
    if [ "$file" = "bw-encrypted-vault-latest.json" ]; then
        continue
    fi

    FILE_DATE=$(echo "$file" | sed -r 's/bw-encrypted-vault_([0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2})\.json/\1/')
    if [ -n "$FILE_DATE" ]; then
        FILE_DATE=$(echo "$FILE_DATE" | sed 's/_/ /g') # replace _ with spwce
        FILE_DATE=$(echo "$FILE_DATE" | sed -r 's/([0-9]{2})-([0-9]{2})-([0-9]{2})$/\1:\2:\3/') # turn "2024-09-11 13-52-20" into "2024-09-11 13:52:20"
        FILE_TIMESTAMP=$(date -d "$FILE_DATE" +%s)
        CURRENT_TIMESTAMP=$(date +%s)
        FILE_AGE_DAYS=$(( (CURRENT_TIMESTAMP - FILE_TIMESTAMP) / 86400 ))
        if [ "$FILE_AGE_DAYS" -ge "$RETENTION_DAYS" ]; then
            log_message "Deleting old backup $file from Google Drive."
            rclone delete "$RCLONE_REMOTE/$file"
        fi
    fi
done

# Log end of the process
log_message "Bitwarden export and upload completed successfully."

