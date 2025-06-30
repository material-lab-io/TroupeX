# DigitalOcean Spaces Setup for TroupeX

## Current Configuration

Your DigitalOcean Space is configured with:
- **Space Name**: troupex-ugc
- **Region**: BLR1 (Bangalore)
- **Public URL**: https://troupex-ugc.blr1.digitaloceanspaces.com

## Next Steps

### 1. Generate Access Keys

1. Go to [DigitalOcean Control Panel](https://cloud.digitalocean.com/)
2. Navigate to **API** → **Spaces Keys**
3. Click **Generate New Key**
4. Give it a name like "troupex-mastodon"
5. Copy the **Access Key** and **Secret Key**

### 2. Update .env.production

Add your access keys to the configuration:

```bash
# Edit the file
nano mastodon/.env.production

# Find these lines and add your keys:
AWS_ACCESS_KEY_ID=your-spaces-access-key-here
AWS_SECRET_ACCESS_KEY=your-spaces-secret-key-here
```

### 3. Configure Space Settings (Optional but Recommended)

In your DigitalOcean Space settings:

1. **Enable CDN** (if not already enabled):
   - Go to your Space settings
   - Click "Settings" → "CDN (Content Delivery Network)"
   - Enable CDN
   - Update S3_ALIAS_HOST to use CDN URL if different

2. **Configure CORS** (for direct uploads):
   - Go to "Settings" → "CORS Configuration"
   - Add this configuration:
   ```json
   [
     {
       "origins": ["https://troupex-preprod.materiallab.io"],
       "allowed_methods": ["GET", "HEAD", "PUT", "POST", "DELETE"],
       "allowed_headers": ["*"],
       "expose_headers": ["ETag"],
       "max_age_seconds": 3000
     }
   ]
   ```

3. **Set Permissions**:
   - Ensure the Space is set to "Public" for file reading
   - Individual files will be publicly accessible

### 4. Restart Services

After adding your credentials:

```bash
cd mastodon
docker-compose -f docker-compose.dev.yml restart
```

### 5. Test Upload

1. Log into your Mastodon instance
2. Go to Settings → Profile
3. Try uploading a profile picture or header image
4. Check if the image appears correctly

### 6. Verify in DigitalOcean

After uploading, you should see files appearing in your Space:
- Profile pictures in: `accounts/avatars/`
- Header images in: `accounts/headers/`
- Media attachments in: `media_attachments/files/`

## Troubleshooting

If uploads still fail:

1. **Check logs**:
   ```bash
   docker-compose -f docker-compose.dev.yml logs -f web | grep -i s3
   ```

2. **Verify credentials**:
   ```bash
   # Test connection with AWS CLI
   aws s3 ls s3://troupex-ugc --endpoint-url https://blr1.digitaloceanspaces.com
   ```

3. **Check Space permissions**:
   - Ensure the access key has read/write permissions
   - Verify the Space allows public read access

## Backup Configuration

To also use Spaces for backups, create another Space:

1. Create a new Space called `troupex-backups`
2. Add to .env.production:
   ```bash
   S3_BACKUP_BUCKET=troupex-backups
   ```

3. Run backup test:
   ```bash
   ./scripts/backup-postgres.sh
   ```

## Cost Estimate

- **DigitalOcean Spaces**: $5/month (includes 250GB storage + 1TB transfer)
- **Additional storage**: $0.02/GB/month after 250GB
- **Additional transfer**: $0.01/GB after 1TB

For most Mastodon instances, the base $5/month plan is sufficient.