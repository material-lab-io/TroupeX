# PostgreSQL Backup Setup for TroupeX

This document describes the automated PostgreSQL backup system using GitHub Actions and DigitalOcean Spaces.

## Overview

The backup system runs automatically via GitHub Actions and stores compressed PostgreSQL backups in your DigitalOcean Space (`troupex-backup`). Backups are scheduled to run daily at 3:00 AM IST.

## Features

- **Automated Scheduling**: Daily backups at 3:00 AM IST
- **Multiple Backup Types**: Daily, weekly, and manual backups
- **Compression**: All backups are compressed with gzip
- **Retention Policies**:
  - Daily backups: 30 days
  - Weekly backups: 90 days  
  - Manual backups: 30 days
- **Automatic Cleanup**: Old backups are automatically deleted
- **Backup Verification**: Uploads are verified after completion
- **Optional Notifications**: Slack webhook support

## Setup Instructions

### 1. Add Required GitHub Secrets

Go to your GitHub repository settings → Secrets and variables → Actions, and add:

- `DO_SPACES_ACCESS_KEY` - Your DigitalOcean Spaces access key
- `DO_SPACES_SECRET_KEY` - Your DigitalOcean Spaces secret key
- `SLACK_WEBHOOK` (optional) - Slack webhook URL for notifications

The following secrets should already exist:
- `DROPLET_IP`
- `DROPLET_USER`
- `SSH_PRIVATE_KEY`
- `KNOWN_HOSTS`

### 2. Verify DigitalOcean Space

Ensure your DigitalOcean Space `troupex-backup` exists in the `blr1` region. The workflow will create the following directory structure:

```
troupex-backup/
└── postgres-backups/
    ├── daily/
    ├── weekly/
    └── manual/
```

### 3. Test the Workflow

You can manually trigger a backup to test the setup:

1. Go to Actions → "Scheduled PostgreSQL Backup"
2. Click "Run workflow"
3. Select backup type (manual/daily/weekly)
4. Click "Run workflow"

## Backup Schedule

- **Daily Backups**: Every day at 3:00 AM IST (21:30 UTC)
- **Weekly Backups**: Automatically created on Sundays
- **Manual Backups**: Can be triggered anytime via GitHub Actions

## Backup File Naming

Backups are named with the pattern:
```
mastodon-{type}-{timestamp}.sql.gz
```

Example: `mastodon-daily-2024-01-07-21-30-00.sql.gz`

## Monitoring

### GitHub Actions

Monitor backup status in the Actions tab of your repository. Each run shows:
- Backup size
- Upload status
- Cleanup results
- Current backups list

### Slack Notifications (Optional)

If configured, you'll receive Slack notifications with:
- ✅ Success: Backup type, size, and filename
- ❌ Failure: Error notification with link to logs

## Restore Process

To restore a backup:

1. Download the backup file from DigitalOcean Spaces:
   ```bash
   s3cmd get s3://troupex-backup/postgres-backups/daily/mastodon-daily-YYYY-MM-DD-HH-MM-SS.sql.gz
   ```

2. Copy to your server:
   ```bash
   scp mastodon-daily-*.sql.gz deploy@YOUR_SERVER_IP:/tmp/
   ```

3. Stop the application:
   ```bash
   ssh deploy@YOUR_SERVER_IP
   cd ~/troupex
   docker compose stop web streaming sidekiq
   ```

4. Restore the database:
   ```bash
   # Decompress the backup
   gunzip /tmp/mastodon-daily-*.sql.gz
   
   # Restore to PostgreSQL
   docker compose exec -T db psql -U mastodon mastodon_production < /tmp/mastodon-daily-*.sql
   ```

5. Restart services:
   ```bash
   docker compose start web streaming sidekiq
   ```

## Troubleshooting

### Backup Fails

1. Check GitHub Actions logs for detailed error messages
2. Verify SSH access to your droplet
3. Ensure PostgreSQL container is running
4. Check DigitalOcean Spaces credentials

### Upload Fails

1. Verify DigitalOcean Spaces credentials in GitHub Secrets
2. Check if the Space exists and is accessible
3. Ensure sufficient space in your DigitalOcean account

### Common Issues

- **Empty backup file**: Database container might be down
- **SSH connection failed**: Check SSH key and known_hosts
- **S3 upload error**: Verify Space credentials and region

## Cost Considerations

- DigitalOcean Spaces: $5/month for 250GB storage
- GitHub Actions: Free for public repos, 2000 minutes/month for private
- Estimated storage for 30 daily + 12 weekly backups: ~5-10GB

## Security Notes

- All credentials are stored as GitHub Secrets
- Backups contain sensitive data - ensure Space is private
- Consider encrypting backups for additional security
- Regularly rotate access keys