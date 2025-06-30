#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== TroupeX Deployment Script ===${NC}"
echo -e "${YELLOW}Timestamp: $(date)${NC}"

# Configuration
REGISTRY="ghcr.io"
IMAGE_BASE="${REGISTRY}/material-lab-io/troupex"
APP_DIR="/home/deploy/troupex"
BACKUP_DIR="${APP_DIR}/backups"

# Ensure we're in the right directory
cd ${APP_DIR}

# Function to check if a command succeeded
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1 failed${NC}"
        exit 1
    fi
}

echo -e "${YELLOW}Step 1: Creating backup of current database${NC}"
mkdir -p ${BACKUP_DIR}
if docker compose ps | grep -q "db.*running"; then
    docker compose exec -T db pg_dump -U mastodon mastodon_production | gzip > ${BACKUP_DIR}/backup_$(date +%Y%m%d_%H%M%S).sql.gz
    check_status "Database backup"
    
    # Keep only last 7 backups
    ls -t ${BACKUP_DIR}/backup_*.sql.gz | tail -n +8 | xargs -r rm
fi

echo -e "${YELLOW}Step 2: Pulling latest Docker images${NC}"
docker pull ${IMAGE_BASE}-web:main
check_status "Pull web image"

docker pull ${IMAGE_BASE}-streaming:main
check_status "Pull streaming image"

echo -e "${YELLOW}Step 3: Stopping current containers${NC}"
docker compose -f docker-compose.yml -f docker-compose.production.yml down
check_status "Stop containers"

echo -e "${YELLOW}Step 4: Starting database and Redis${NC}"
docker compose -f docker-compose.yml -f docker-compose.production.yml up -d db redis
check_status "Start database and Redis"

# Wait for database to be ready
echo -e "${YELLOW}Waiting for database to be ready...${NC}"
sleep 10

echo -e "${YELLOW}Step 5: Running database migrations${NC}"
docker compose -f docker-compose.yml -f docker-compose.production.yml run --rm web rails db:migrate
check_status "Database migrations"

echo -e "${YELLOW}Step 6: Precompiling assets${NC}"
docker compose -f docker-compose.yml -f docker-compose.production.yml run --rm web rails assets:precompile
check_status "Asset precompilation"

echo -e "${YELLOW}Step 7: Starting all services${NC}"
docker compose -f docker-compose.yml -f docker-compose.production.yml up -d
check_status "Start all services"

echo -e "${YELLOW}Step 8: Cleaning up old images${NC}"
docker image prune -f
check_status "Image cleanup"

echo -e "${YELLOW}Step 9: Health check${NC}"
sleep 15

# Check if services are running
services=("web" "streaming" "sidekiq" "db" "redis")
all_healthy=true

for service in "${services[@]}"; do
    if docker compose ps | grep -q "${service}.*running"; then
        echo -e "${GREEN}✓ ${service} is running${NC}"
    else
        echo -e "${RED}✗ ${service} is not running${NC}"
        all_healthy=false
    fi
done

# Check web endpoint
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health || echo "000")
if [ "$response" = "200" ]; then
    echo -e "${GREEN}✓ Web application is responding${NC}"
else
    echo -e "${RED}✗ Web application health check failed (HTTP ${response})${NC}"
    all_healthy=false
fi

if $all_healthy; then
    echo -e "${GREEN}=== Deployment completed successfully! ===${NC}"
    
    # Optional: Clear cache
    docker compose exec -T web rails cache:clear
    docker compose exec -T redis redis-cli FLUSHALL
    
    # Log deployment
    echo "$(date): Deployment successful" >> ${APP_DIR}/deployments.log
else
    echo -e "${RED}=== Deployment completed with errors ===${NC}"
    echo -e "${YELLOW}Check logs with: docker compose logs${NC}"
    exit 1
fi

echo -e "${BLUE}Deployment finished at: $(date)${NC}"