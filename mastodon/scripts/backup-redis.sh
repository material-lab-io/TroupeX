#!/bin/bash
# Redis Backup Script for TroupeX
# Backs up Redis data and uploads to S3

set -euo pipefail

# Configuration
BACKUP_DIR="/tmp/redis-backups"
S3_BACKUP_BUCKET="${S3_BACKUP_BUCKET:-troupex-backups}"
S3_BACKUP_PREFIX="${S3_BACKUP_PREFIX:-redis}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="troupex_redis_${TIMESTAMP}"

# Redis connection
REDIS_CONTAINER="mastodon_redis_1"

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
            --data "{\"text\":\"Redis Backup ${status}: ${message}\"}" \
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
    log "Starting Redis backup..."
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Trigger Redis BGSAVE
    log "Triggering Redis background save..."
    docker exec "$REDIS_CONTAINER" redis-cli BGSAVE
    
    # Wait for background save to complete
    log "Waiting for background save to complete..."
    while [ "$(docker exec "$REDIS_CONTAINER" redis-cli LASTSAVE)" == "$(docker exec "$REDIS_CONTAINER" redis-cli LASTSAVE)" ]; do
        sleep 1
    done
    
    # Copy dump.rdb from container
    log "Copying Redis dump file..."
    if docker cp "${REDIS_CONTAINER}:/data/dump.rdb" "${BACKUP_DIR}/${BACKUP_NAME}.rdb"; then
        log "Redis dump copied successfully"
    else
        log "ERROR: Failed to copy Redis dump"
        notify "FAILED" "Failed to copy Redis dump"
        exit 1
    fi
    
    # Get Redis info
    REDIS_INFO=$(docker exec "$REDIS_CONTAINER" redis-cli INFO memory | grep used_memory_human | cut -d: -f2 | tr -d '\r')
    log "Redis memory usage: ${REDIS_INFO}"
    
    # Compress backup
    log "Compressing backup..."
    gzip -9 "${BACKUP_DIR}/${BACKUP_NAME}.rdb"
    COMPRESSED_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}.rdb.gz" | cut -f1)
    log "Compressed size: ${COMPRESSED_SIZE}"
    
    # Upload to S3
    log "Uploading to S3..."
    if aws s3 cp "${BACKUP_DIR}/${BACKUP_NAME}.rdb.gz" \
        "s3://${S3_BACKUP_BUCKET}/${S3_BACKUP_PREFIX}/${BACKUP_NAME}.rdb.gz" \
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
    "redis_version": "$(docker exec "$REDIS_CONTAINER" redis-cli INFO server | grep redis_version | cut -d: -f2 | tr -d '\r')",
    "memory_usage": "${REDIS_INFO}",
    "size_compressed": "${COMPRESSED_SIZE}",
    "backup_type": "RDB snapshot"
}
EOF
    
    # Upload metadata
    aws s3 cp "${BACKUP_DIR}/${BACKUP_NAME}.metadata.json" \
        "s3://${S3_BACKUP_BUCKET}/${S3_BACKUP_PREFIX}/${BACKUP_NAME}.metadata.json"
    
    # Clean up old backups
    log "Cleaning up old backups (older than ${RETENTION_DAYS} days)..."
    aws s3 ls "s3://${S3_BACKUP_BUCKET}/${S3_BACKUP_PREFIX}/" | \
        grep "\.rdb\.gz$" | \
        while read -r line; do
            backup_date=$(echo "$line" | awk '{print $1}')
            backup_file=$(echo "$line" | awk '{print $4}')
            
            if [ -n "$backup_date" ] && [ -n "$backup_file" ]; then
                days_old=$(( ($(date +%s) - $(date -d "$backup_date" +%s)) / 86400 ))
                
                if [ "$days_old" -gt "$RETENTION_DAYS" ]; then
                    log "Deleting old backup: $backup_file (${days_old} days old)"
                    aws s3 rm "s3://${S3_BACKUP_BUCKET}/${S3_BACKUP_PREFIX}/${backup_file}"
                    # Also delete metadata
                    aws s3 rm "s3://${S3_BACKUP_BUCKET}/${S3_BACKUP_PREFIX}/${backup_file%.rdb.gz}.metadata.json" 2>/dev/null || true
                fi
            fi
        done
    
    # Verify backup
    log "Verifying backup..."
    if aws s3 ls "s3://${S3_BACKUP_BUCKET}/${S3_BACKUP_PREFIX}/${BACKUP_NAME}.rdb.gz" > /dev/null 2>&1; then
        log "Backup verified successfully"
        notify "SUCCESS" "Redis backup completed. Size: ${COMPRESSED_SIZE}"
    else
        log "ERROR: Backup verification failed"
        notify "FAILED" "Backup verification failed"
        exit 1
    fi
    
    log "Redis backup completed successfully"
}

# Run main function
main "$@"