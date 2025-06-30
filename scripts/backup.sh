#!/bin/bash
set -euo pipefail

# Configuration
APP_DIR="/home/deploy/troupex"
BACKUP_DIR="${APP_DIR}/backups"
BACKUP_RETENTION_DAYS=7
S3_BUCKET="${S3_BACKUP_BUCKET:-}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== TroupeX Backup Script ===${NC}"
echo -e "${YELLOW}Timestamp: ${TIMESTAMP}${NC}"

# Create backup directory if it doesn't exist
mkdir -p ${BACKUP_DIR}

# Function to check if a command succeeded
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1 failed${NC}"
        exit 1
    fi
}

# Database backup
echo -e "${YELLOW}1. Backing up PostgreSQL database...${NC}"
cd ${APP_DIR}

if docker compose ps | grep -q "db.*running"; then
    docker compose exec -T db pg_dump -U mastodon mastodon_production | gzip > ${BACKUP_DIR}/db_${TIMESTAMP}.sql.gz
    check_status "Database backup"
    
    # Get backup size
    DB_SIZE=$(du -h ${BACKUP_DIR}/db_${TIMESTAMP}.sql.gz | cut -f1)
    echo -e "   Database backup size: ${DB_SIZE}"
else
    echo -e "${RED}Database container is not running${NC}"
    exit 1
fi

# Redis backup
echo -e "${YELLOW}2. Backing up Redis data...${NC}"
if docker compose ps | grep -q "redis.*running"; then
    docker compose exec -T redis redis-cli BGSAVE
    sleep 5  # Wait for background save to complete
    docker compose cp redis:/data/dump.rdb ${BACKUP_DIR}/redis_${TIMESTAMP}.rdb
    check_status "Redis backup"
else
    echo -e "${YELLOW}Redis container is not running, skipping...${NC}"
fi

# Media files backup (optional, can be large)
if [ "${BACKUP_MEDIA:-false}" = "true" ]; then
    echo -e "${YELLOW}3. Backing up media files...${NC}"
    tar -czf ${BACKUP_DIR}/media_${TIMESTAMP}.tar.gz -C ${APP_DIR}/mastodon/public system
    check_status "Media backup"
    
    MEDIA_SIZE=$(du -h ${BACKUP_DIR}/media_${TIMESTAMP}.tar.gz | cut -f1)
    echo -e "   Media backup size: ${MEDIA_SIZE}"
fi

# Configuration backup
echo -e "${YELLOW}4. Backing up configuration...${NC}"
tar -czf ${BACKUP_DIR}/config_${TIMESTAMP}.tar.gz \
    -C ${APP_DIR} \
    mastodon/.env.production \
    docker-compose.yml \
    docker-compose.production.yml \
    nginx/ \
    2>/dev/null || true
check_status "Configuration backup"

# Upload to S3 if configured
if [ -n "${S3_BUCKET}" ] && command -v aws &> /dev/null; then
    echo -e "${YELLOW}5. Uploading to S3...${NC}"
    
    aws s3 cp ${BACKUP_DIR}/db_${TIMESTAMP}.sql.gz s3://${S3_BUCKET}/troupex/db/
    check_status "Database upload to S3"
    
    aws s3 cp ${BACKUP_DIR}/config_${TIMESTAMP}.tar.gz s3://${S3_BUCKET}/troupex/config/
    check_status "Configuration upload to S3"
    
    if [ -f ${BACKUP_DIR}/redis_${TIMESTAMP}.rdb ]; then
        aws s3 cp ${BACKUP_DIR}/redis_${TIMESTAMP}.rdb s3://${S3_BUCKET}/troupex/redis/
        check_status "Redis upload to S3"
    fi
    
    if [ -f ${BACKUP_DIR}/media_${TIMESTAMP}.tar.gz ]; then
        aws s3 cp ${BACKUP_DIR}/media_${TIMESTAMP}.tar.gz s3://${S3_BUCKET}/troupex/media/
        check_status "Media upload to S3"
    fi
fi

# Clean up old local backups
echo -e "${YELLOW}6. Cleaning up old backups...${NC}"
find ${BACKUP_DIR} -name "db_*.sql.gz" -mtime +${BACKUP_RETENTION_DAYS} -delete
find ${BACKUP_DIR} -name "redis_*.rdb" -mtime +${BACKUP_RETENTION_DAYS} -delete
find ${BACKUP_DIR} -name "media_*.tar.gz" -mtime +${BACKUP_RETENTION_DAYS} -delete
find ${BACKUP_DIR} -name "config_*.tar.gz" -mtime +${BACKUP_RETENTION_DAYS} -delete
check_status "Cleanup old backups"

# Log backup completion
echo "$(date): Backup completed successfully" >> ${APP_DIR}/backup.log

echo -e "${GREEN}=== Backup completed successfully! ===${NC}"
echo -e "Backups stored in: ${BACKUP_DIR}"

# Display backup summary
echo -e "\n${YELLOW}Backup Summary:${NC}"
ls -lh ${BACKUP_DIR}/*${TIMESTAMP}*