#!/bin/bash
# PostgreSQL Restore Script for TroupeX
# Restores database from S3 backup

set -euo pipefail

# Configuration
BACKUP_DIR="/tmp/postgres-restore"
S3_BACKUP_BUCKET="${S3_BACKUP_BUCKET:-troupex-backups}"
S3_BACKUP_PREFIX="${S3_BACKUP_PREFIX:-postgres}"

# Database connection
DB_CONTAINER="mastodon_db_1"
DB_NAME="${DB_NAME:-postgres}"
DB_USER="${DB_USER:-postgres}"

# Functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

cleanup() {
    log "Cleaning up temporary files..."
    rm -rf "$BACKUP_DIR"
}

trap cleanup EXIT

# Main restore process
main() {
    local backup_file="${1:-}"
    
    if [ -z "$backup_file" ]; then
        # List available backups
        log "Available backups:"
        aws s3 ls "s3://${S3_BACKUP_BUCKET}/${S3_BACKUP_PREFIX}/" | \
            grep "\.sql\.gz$" | sort -r | head -20
        
        echo
        echo "Usage: $0 <backup_filename>"
        echo "Example: $0 troupex_postgres_20250630_120000.sql.gz"
        exit 1
    fi
    
    log "Starting PostgreSQL restore from: $backup_file"
    
    # Confirmation
    echo "WARNING: This will replace all data in the database!"
    echo "Database: $DB_NAME in container: $DB_CONTAINER"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        log "Restore cancelled"
        exit 0
    fi
    
    # Create restore directory
    mkdir -p "$BACKUP_DIR"
    
    # Download backup
    log "Downloading backup from S3..."
    if ! aws s3 cp "s3://${S3_BACKUP_BUCKET}/${S3_BACKUP_PREFIX}/${backup_file}" \
        "${BACKUP_DIR}/${backup_file}"; then
        log "ERROR: Failed to download backup"
        exit 1
    fi
    
    # Download metadata if exists
    metadata_file="${backup_file%.sql.gz}.metadata.json"
    if aws s3 cp "s3://${S3_BACKUP_BUCKET}/${S3_BACKUP_PREFIX}/${metadata_file}" \
        "${BACKUP_DIR}/${metadata_file}" 2>/dev/null; then
        log "Backup metadata:"
        cat "${BACKUP_DIR}/${metadata_file}"
        echo
    fi
    
    # Stop Mastodon services (except database)
    log "Stopping Mastodon services..."
    docker-compose -f docker-compose.dev.yml stop web streaming sidekiq
    
    # Decompress backup
    log "Decompressing backup..."
    gunzip -k "${BACKUP_DIR}/${backup_file}"
    sql_file="${BACKUP_DIR}/${backup_file%.gz}"
    
    # Create restore point
    log "Creating restore point..."
    docker exec "$DB_CONTAINER" pg_dump -U "$DB_USER" -d "$DB_NAME" \
        --no-owner --clean --if-exists | gzip > "${BACKUP_DIR}/pre_restore_${DB_NAME}_$(date +%Y%m%d_%H%M%S).sql.gz"
    
    # Restore database
    log "Restoring database..."
    if docker exec -i "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" < "$sql_file"; then
        log "Database restored successfully"
    else
        log "ERROR: Database restore failed"
        exit 1
    fi
    
    # Run post-restore tasks
    log "Running post-restore tasks..."
    
    # Update database schema if needed
    docker-compose -f docker-compose.dev.yml run --rm web bundle exec rails db:migrate
    
    # Clear cache
    docker-compose -f docker-compose.dev.yml run --rm web bundle exec rails cache:clear
    
    # Restart services
    log "Starting Mastodon services..."
    docker-compose -f docker-compose.dev.yml start web streaming sidekiq
    
    # Wait for services to be healthy
    log "Waiting for services to be healthy..."
    sleep 10
    
    # Verify services
    if docker-compose -f docker-compose.dev.yml ps | grep -E "(web|streaming|sidekiq).*Up.*healthy"; then
        log "Services are healthy"
    else
        log "WARNING: Some services may not be healthy"
        docker-compose -f docker-compose.dev.yml ps
    fi
    
    log "PostgreSQL restore completed successfully"
    log "Pre-restore backup saved as: pre_restore_${DB_NAME}_$(date +%Y%m%d_%H%M%S).sql.gz"
}

# Run main function
main "$@"