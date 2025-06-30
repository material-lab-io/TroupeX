#!/bin/bash
# PostgreSQL Backup Script for TroupeX
# Performs daily backups and uploads to S3

set -euo pipefail

# Configuration
BACKUP_DIR="/tmp/postgres-backups"
S3_BACKUP_BUCKET="${S3_BACKUP_BUCKET:-troupex-backups}"
S3_BACKUP_PREFIX="${S3_BACKUP_PREFIX:-postgres}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="troupex_postgres_${TIMESTAMP}"

# Database connection (from Docker)
DB_CONTAINER="mastodon_db_1"
DB_NAME="${DB_NAME:-postgres}"
DB_USER="${DB_USER:-postgres}"

# Notification webhook (optional)
SLACK_WEBHOOK="${BACKUP_SLACK_WEBHOOK:-}"

# Functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

notify() {
    local status=$1
    local message=$2
    
    if [ -n "$SLACK_WEBHOOK" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"PostgreSQL Backup ${status}: ${message}\"}" \
            "$SLACK_WEBHOOK" 2>/dev/null || true
    fi
}

cleanup() {
    log "Cleaning up temporary files..."
    rm -rf "${BACKUP_DIR}/${BACKUP_NAME}"*
}

trap cleanup EXIT

# Main backup process
main() {
    log "Starting PostgreSQL backup..."
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Perform backup
    log "Dumping database..."
    if docker exec "$DB_CONTAINER" pg_dump -U "$DB_USER" -d "$DB_NAME" \
        --no-owner --clean --if-exists > "${BACKUP_DIR}/${BACKUP_NAME}.sql"; then
        log "Database dump completed successfully"
    else
        log "ERROR: Database dump failed"
        notify "FAILED" "Database dump failed"
        exit 1
    fi
    
    # Get database size for logging
    DB_SIZE=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c \
        "SELECT pg_size_pretty(pg_database_size('${DB_NAME}'));")
    log "Database size: ${DB_SIZE}"
    
    # Compress backup
    log "Compressing backup..."
    gzip -9 "${BACKUP_DIR}/${BACKUP_NAME}.sql"
    COMPRESSED_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}.sql.gz" | cut -f1)
    log "Compressed size: ${COMPRESSED_SIZE}"
    
    # Upload to S3
    log "Uploading to S3..."
    if aws s3 cp "${BACKUP_DIR}/${BACKUP_NAME}.sql.gz" \
        "s3://${S3_BACKUP_BUCKET}/${S3_BACKUP_PREFIX}/${BACKUP_NAME}.sql.gz" \
        --storage-class STANDARD_IA; then
        log "Upload completed successfully"
    else
        log "ERROR: S3 upload failed"
        notify "FAILED" "S3 upload failed"
        exit 1
    fi
    
    # Create metadata file
    cat > "${BACKUP_DIR}/${BACKUP_NAME}.metadata.json" <<EOF
{
    "timestamp": "${TIMESTAMP}",
    "database": "${DB_NAME}",
    "size_original": "${DB_SIZE}",
    "size_compressed": "${COMPRESSED_SIZE}",
    "mastodon_version": "$(docker exec mastodon_web_1 bundle exec rails version 2>/dev/null || echo 'unknown')",
    "backup_tool": "pg_dump",
    "compression": "gzip -9"
}
EOF
    
    # Upload metadata
    aws s3 cp "${BACKUP_DIR}/${BACKUP_NAME}.metadata.json" \
        "s3://${S3_BACKUP_BUCKET}/${S3_BACKUP_PREFIX}/${BACKUP_NAME}.metadata.json"
    
    # Clean up old backups
    log "Cleaning up old backups (older than ${RETENTION_DAYS} days)..."
    aws s3 ls "s3://${S3_BACKUP_BUCKET}/${S3_BACKUP_PREFIX}/" | \
        while read -r line; do
            backup_date=$(echo "$line" | awk '{print $1}')
            backup_file=$(echo "$line" | awk '{print $4}')
            
            if [ -n "$backup_date" ] && [ -n "$backup_file" ]; then
                days_old=$(( ($(date +%s) - $(date -d "$backup_date" +%s)) / 86400 ))
                
                if [ "$days_old" -gt "$RETENTION_DAYS" ]; then
                    log "Deleting old backup: $backup_file (${days_old} days old)"
                    aws s3 rm "s3://${S3_BACKUP_BUCKET}/${S3_BACKUP_PREFIX}/${backup_file}"
                fi
            fi
        done
    
    # Verify backup
    log "Verifying backup..."
    if aws s3 ls "s3://${S3_BACKUP_BUCKET}/${S3_BACKUP_PREFIX}/${BACKUP_NAME}.sql.gz" > /dev/null 2>&1; then
        log "Backup verified successfully"
        notify "SUCCESS" "Database backup completed. Size: ${COMPRESSED_SIZE}"
    else
        log "ERROR: Backup verification failed"
        notify "FAILED" "Backup verification failed"
        exit 1
    fi
    
    log "PostgreSQL backup completed successfully"
}

# Run main function
main "$@"