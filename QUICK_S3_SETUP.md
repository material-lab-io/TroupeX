# Quick S3 Setup for TroupeX

## Option 1: AWS S3

1. **Create S3 Bucket**:
   ```bash
   aws s3 mb s3://troupex-media --region us-east-1
   ```

2. **Create IAM User**:
   - Go to AWS Console → IAM → Users → Create User
   - Name: `troupex-s3-user`
   - Access type: Programmatic access
   - Attach policy: `AmazonS3FullAccess` (or create custom policy)

3. **Add to .env.production**:
   ```bash
   # S3 Configuration
   S3_ENABLED=true
   S3_BUCKET=troupex-media
   AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
   AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
   S3_REGION=us-east-1
   ```

## Option 2: DigitalOcean Spaces (Easier & Cheaper)

1. **Create Space**:
   - Go to DigitalOcean → Spaces → Create Space
   - Name: `troupex-media`
   - Region: NYC3 (or closest to you)
   - Enable CDN (optional but recommended)

2. **Generate Access Keys**:
   - Go to API → Spaces Keys → Generate New Key
   - Name: `troupex-key`

3. **Add to .env.production**:
   ```bash
   # S3 Configuration for DigitalOcean Spaces
   S3_ENABLED=true
   S3_BUCKET=troupex-media
   AWS_ACCESS_KEY_ID=your-spaces-access-key
   AWS_SECRET_ACCESS_KEY=your-spaces-secret-key
   S3_REGION=nyc3
   S3_ENDPOINT=https://nyc3.digitaloceanspaces.com
   S3_HOSTNAME=nyc3.digitaloceanspaces.com
   # Optional: Use Spaces CDN
   # S3_ALIAS_HOST=troupex-media.nyc3.cdn.digitaloceanspaces.com
   ```

## Option 3: MinIO (Self-hosted)

1. **Run MinIO**:
   ```bash
   docker run -d \
     -p 9000:9000 \
     -p 9001:9001 \
     --name minio \
     -e MINIO_ROOT_USER=minioadmin \
     -e MINIO_ROOT_PASSWORD=minioadmin \
     -v ~/minio/data:/data \
     minio/minio server /data --console-address ":9001"
   ```

2. **Create Bucket**:
   - Access MinIO Console at http://localhost:9001
   - Create bucket: `troupex-media`

3. **Add to .env.production**:
   ```bash
   # S3 Configuration for MinIO
   S3_ENABLED=true
   S3_BUCKET=troupex-media
   AWS_ACCESS_KEY_ID=minioadmin
   AWS_SECRET_ACCESS_KEY=minioadmin
   S3_ENDPOINT=http://localhost:9000
   S3_OVERRIDE_PATH_STYLE=true
   S3_FORCE_SINGLE_REQUEST=true
   S3_PROTOCOL=http
   ```

## Apply Configuration

1. **Update .env.production**:
   ```bash
   nano .env.production
   # Add your chosen S3 configuration
   ```

2. **Restart Services**:
   ```bash
   docker-compose -f docker-compose.dev.yml restart
   ```

3. **Test Upload**:
   - Try uploading a profile picture
   - Check S3 bucket for the uploaded file

## Quick Fix for Current Permission Issue

If you need to fix the upload issue immediately without S3:

```bash
# Fix permissions (temporary solution)
sudo chown -R 991:991 public/system
docker-compose -f docker-compose.dev.yml restart web
```

## Backup Setup

After S3 is working, set up automated backups:

```bash
# Configure backup bucket
export S3_BACKUP_BUCKET=troupex-backups

# Test backup script
./scripts/backup-postgres.sh

# Install cron jobs for automated backups
crontab -e
# Add: 0 2 * * * /home/kanaba/troupex5/TroupeX/scripts/backup-postgres.sh
```

## Costs

- **AWS S3**: ~$0.023/GB/month + transfer costs
- **DigitalOcean Spaces**: $5/month for 250GB (includes 1TB transfer)
- **MinIO**: Free (self-hosted)

## Recommendation

For production, I recommend **DigitalOcean Spaces** because:
- Fixed pricing ($5/month)
- Built-in CDN
- S3-compatible
- No surprise bills
- Easy to set up