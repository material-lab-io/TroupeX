# TroupeX S3 and Backup Configuration Guide

## S3 Configuration for Media Storage

### Required Environment Variables

Add these to your `.env.production` file:

```bash
# Enable S3
S3_ENABLED=true

# Basic S3 Credentials
S3_BUCKET=your-bucket-name
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key

# Region Configuration (default: us-east-1)
S3_REGION=us-east-1

# Optional: Custom endpoint for S3-compatible services (DigitalOcean Spaces, MinIO, etc)
# S3_ENDPOINT=https://nyc3.digitaloceanspaces.com
# S3_HOSTNAME=nyc3.digitaloceanspaces.com

# Optional: CDN/Custom domain for serving files
# S3_ALIAS_HOST=cdn.yourdomain.com

# Optional: Permissions (default: public-read)
# S3_PERMISSION=public-read

# Optional: Storage class for cost optimization
# S3_STORAGE_CLASS=STANDARD_IA

# Optional: Protocol (default: https)
# S3_PROTOCOL=https

# Optional: Key prefix for organizing files
# S3_KEY_PREFIX=mastodon/prod
```

### S3-Compatible Services Configuration Examples

#### AWS S3
```bash
S3_ENABLED=true
S3_BUCKET=troupex-media
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
S3_REGION=us-west-2
```

#### DigitalOcean Spaces
```bash
S3_ENABLED=true
S3_BUCKET=troupex-media
AWS_ACCESS_KEY_ID=your-spaces-key
AWS_SECRET_ACCESS_KEY=your-spaces-secret
S3_REGION=nyc3
S3_ENDPOINT=https://nyc3.digitaloceanspaces.com
S3_HOSTNAME=nyc3.digitaloceanspaces.com
```

#### MinIO (Self-hosted)
```bash
S3_ENABLED=true
S3_BUCKET=troupex-media
AWS_ACCESS_KEY_ID=minioadmin
AWS_SECRET_ACCESS_KEY=minioadmin
S3_ENDPOINT=https://minio.yourdomain.com
S3_OVERRIDE_PATH_STYLE=true
S3_FORCE_SINGLE_REQUEST=true
```

## Backup Strategy

### 1. PostgreSQL Backup

#### Automated Daily Backups
Create a backup script that:
- Performs daily pg_dump
- Compresses the backup
- Uploads to S3
- Retains last 30 days of backups
- Sends notifications on failure

#### WAL Archiving (Point-in-Time Recovery)
- Configure PostgreSQL for continuous archiving
- Stream WAL files to S3
- Enables recovery to any point in time

### 2. S3/Media Backup

#### Cross-Region Replication
- Enable S3 versioning
- Configure cross-region replication to another bucket
- Protects against regional failures

#### Lifecycle Policies
- Move older media to cheaper storage classes
- Archive deleted media for 30 days before permanent deletion

### 3. Redis Backup
- Daily RDB snapshots
- Optional: AOF (Append Only File) for better durability

## Implementation Scripts

### 1. Database Backup Script
`/home/kanaba/troupex5/TroupeX/scripts/backup-postgres.sh`

### 2. S3 Sync Script
`/home/kanaba/troupex5/TroupeX/scripts/backup-s3.sh`

### 3. Restore Scripts
`/home/kanaba/troupex5/TroupeX/scripts/restore-postgres.sh`
`/home/kanaba/troupex5/TroupeX/scripts/restore-s3.sh`

### 4. Monitoring Script
`/home/kanaba/troupex5/TroupeX/scripts/monitor-backups.sh`

## Backup Schedule

### Daily
- PostgreSQL full backup at 2 AM
- Redis RDB snapshot at 3 AM
- Backup verification at 4 AM

### Continuous
- PostgreSQL WAL archiving
- S3 cross-region replication

### Weekly
- Full system backup test restore (staging environment)

### Monthly
- Backup retention cleanup
- Storage cost optimization review

## Disaster Recovery Plan

### RTO (Recovery Time Objective): 4 hours
### RPO (Recovery Point Objective): 1 hour

### Recovery Procedures
1. **Database Failure**: Restore from latest backup + WAL replay
2. **S3 Failure**: Failover to replica bucket
3. **Complete System Failure**: Full restore from backups

## Monitoring and Alerts

### Set up alerts for:
- Backup job failures
- S3 bucket size anomalies
- Database size growth
- Replication lag

### Tools:
- CloudWatch (AWS)
- Grafana + Prometheus
- Custom health checks

## Cost Optimization

### S3 Storage Classes
- **Standard**: First 30 days (frequently accessed)
- **Standard-IA**: 30-90 days (infrequent access)
- **Glacier Flexible**: 90+ days (archival)

### Estimated Monthly Costs
- S3 Storage: ~$50-200 (depending on media volume)
- S3 Transfer: ~$20-100 (depending on traffic)
- Backup Storage: ~$20-50
- Total: ~$90-350/month

## Security Best Practices

1. **Encryption**
   - Enable S3 bucket encryption (SSE-S3 or SSE-KMS)
   - Encrypt backups before upload
   - Use encrypted connections (HTTPS)

2. **Access Control**
   - Use IAM roles instead of keys where possible
   - Implement least privilege access
   - Enable MFA for deletion
   - Regular key rotation

3. **Monitoring**
   - Enable S3 access logging
   - CloudTrail for API calls
   - Regular security audits

## Next Steps

1. Choose your S3 provider (AWS, DigitalOcean, etc.)
2. Create S3 bucket with proper settings
3. Generate access credentials
4. Update .env.production
5. Implement backup scripts
6. Set up monitoring
7. Test disaster recovery procedure