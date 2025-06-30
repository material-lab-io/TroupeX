#!/bin/bash
# S3 Backup Setup Script for TroupeX
# Sets up S3 bucket with proper configuration for backups and media storage

set -euo pipefail

# Configuration
MEDIA_BUCKET="${S3_BUCKET:-troupex-media}"
BACKUP_BUCKET="${S3_BACKUP_BUCKET:-troupex-backups}"
REGION="${S3_REGION:-us-east-1}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Check AWS CLI
check_prerequisites() {
    log "Checking prerequisites..."
    
    if ! command -v aws &> /dev/null; then
        log "ERROR: AWS CLI not found. Please install it first."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        log "ERROR: AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    log "Prerequisites check passed"
}

# Create and configure media bucket
setup_media_bucket() {
    log "Setting up media bucket: $MEDIA_BUCKET"
    
    # Create bucket if it doesn't exist
    if aws s3 ls "s3://${MEDIA_BUCKET}" 2>&1 | grep -q 'NoSuchBucket'; then
        log "Creating bucket..."
        aws s3 mb "s3://${MEDIA_BUCKET}" --region "$REGION"
    else
        log "Bucket already exists"
    fi
    
    # Enable versioning
    log "Enabling versioning..."
    aws s3api put-bucket-versioning \
        --bucket "$MEDIA_BUCKET" \
        --versioning-configuration Status=Enabled
    
    # Set up CORS for web uploads
    log "Configuring CORS..."
    cat > /tmp/cors.json <<EOF
{
    "CORSRules": [
        {
            "AllowedHeaders": ["*"],
            "AllowedMethods": ["GET", "HEAD", "PUT", "POST", "DELETE"],
            "AllowedOrigins": ["*"],
            "ExposeHeaders": ["ETag"],
            "MaxAgeSeconds": 3000
        }
    ]
}
EOF
    aws s3api put-bucket-cors --bucket "$MEDIA_BUCKET" --cors-configuration file:///tmp/cors.json
    
    # Set up lifecycle policy
    log "Configuring lifecycle policy..."
    cat > /tmp/lifecycle.json <<EOF
{
    "Rules": [
        {
            "Id": "MoveToIA",
            "Status": "Enabled",
            "Transitions": [
                {
                    "Days": 30,
                    "StorageClass": "STANDARD_IA"
                },
                {
                    "Days": 90,
                    "StorageClass": "GLACIER"
                }
            ],
            "NoncurrentVersionTransitions": [
                {
                    "NoncurrentDays": 7,
                    "StorageClass": "STANDARD_IA"
                }
            ],
            "NoncurrentVersionExpiration": {
                "NoncurrentDays": 30
            }
        }
    ]
}
EOF
    aws s3api put-bucket-lifecycle-configuration \
        --bucket "$MEDIA_BUCKET" \
        --lifecycle-configuration file:///tmp/lifecycle.json
    
    # Enable server-side encryption
    log "Enabling encryption..."
    aws s3api put-bucket-encryption \
        --bucket "$MEDIA_BUCKET" \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'
    
    log "Media bucket setup completed"
}

# Create and configure backup bucket
setup_backup_bucket() {
    log "Setting up backup bucket: $BACKUP_BUCKET"
    
    # Create bucket if it doesn't exist
    if aws s3 ls "s3://${BACKUP_BUCKET}" 2>&1 | grep -q 'NoSuchBucket'; then
        log "Creating bucket..."
        aws s3 mb "s3://${BACKUP_BUCKET}" --region "$REGION"
    else
        log "Bucket already exists"
    fi
    
    # Enable versioning
    log "Enabling versioning..."
    aws s3api put-bucket-versioning \
        --bucket "$BACKUP_BUCKET" \
        --versioning-configuration Status=Enabled
    
    # Set up lifecycle for backup retention
    log "Configuring backup retention policy..."
    cat > /tmp/backup-lifecycle.json <<EOF
{
    "Rules": [
        {
            "Id": "BackupRetention",
            "Status": "Enabled",
            "Transitions": [
                {
                    "Days": 7,
                    "StorageClass": "STANDARD_IA"
                },
                {
                    "Days": 30,
                    "StorageClass": "GLACIER"
                }
            ],
            "Expiration": {
                "Days": 365
            }
        }
    ]
}
EOF
    aws s3api put-bucket-lifecycle-configuration \
        --bucket "$BACKUP_BUCKET" \
        --lifecycle-configuration file:///tmp/backup-lifecycle.json
    
    # Enable encryption
    log "Enabling encryption..."
    aws s3api put-bucket-encryption \
        --bucket "$BACKUP_BUCKET" \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'
    
    # Enable MFA delete protection (optional)
    # aws s3api put-bucket-versioning \
    #     --bucket "$BACKUP_BUCKET" \
    #     --versioning-configuration Status=Enabled,MFADelete=Enabled \
    #     --mfa "arn:aws:iam::123456789012:mfa/user 123456"
    
    log "Backup bucket setup completed"
}

# Create IAM policy for Mastodon
create_iam_policy() {
    log "Creating IAM policy for Mastodon..."
    
    cat > /tmp/mastodon-s3-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": [
                "arn:aws:s3:::${MEDIA_BUCKET}",
                "arn:aws:s3:::${BACKUP_BUCKET}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:PutObjectAcl"
            ],
            "Resource": [
                "arn:aws:s3:::${MEDIA_BUCKET}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${BACKUP_BUCKET}/*"
            ]
        }
    ]
}
EOF
    
    # Create policy
    aws iam create-policy \
        --policy-name TroupeXS3Policy \
        --policy-document file:///tmp/mastodon-s3-policy.json \
        --description "S3 access policy for TroupeX Mastodon instance" || \
        log "Policy might already exist"
    
    log "IAM policy created/updated"
}

# Setup cron jobs
setup_cron_jobs() {
    log "Setting up cron jobs..."
    
    # Create cron job for daily backups
    cat > /tmp/troupex-backup-cron <<EOF
# TroupeX Backup Schedule
# PostgreSQL backup daily at 2 AM
0 2 * * * /home/kanaba/troupex5/TroupeX/scripts/backup-postgres.sh >> /var/log/troupex-backup.log 2>&1

# Redis backup daily at 3 AM
0 3 * * * /home/kanaba/troupex5/TroupeX/scripts/backup-redis.sh >> /var/log/troupex-backup.log 2>&1

# Backup verification daily at 4 AM
0 4 * * * /home/kanaba/troupex5/TroupeX/scripts/verify-backups.sh >> /var/log/troupex-backup.log 2>&1

# Weekly backup test restore (Sunday at 5 AM)
0 5 * * 0 /home/kanaba/troupex5/TroupeX/scripts/test-restore.sh >> /var/log/troupex-backup.log 2>&1
EOF
    
    log "Cron jobs configuration created at /tmp/troupex-backup-cron"
    log "To install: crontab /tmp/troupex-backup-cron"
}

# Generate environment variables
generate_env_vars() {
    log "Generating environment variables..."
    
    cat > /tmp/s3-env-vars.txt <<EOF
# Add these to your .env.production file:

# S3 Configuration
S3_ENABLED=true
S3_BUCKET=${MEDIA_BUCKET}
AWS_ACCESS_KEY_ID=<your-access-key>
AWS_SECRET_ACCESS_KEY=<your-secret-key>
S3_REGION=${REGION}

# Backup Configuration
S3_BACKUP_BUCKET=${BACKUP_BUCKET}

# Optional: CDN configuration
# S3_ALIAS_HOST=cdn.yourdomain.com

# Optional: For DigitalOcean Spaces or other S3-compatible services
# S3_ENDPOINT=https://nyc3.digitaloceanspaces.com
# S3_HOSTNAME=nyc3.digitaloceanspaces.com
EOF
    
    log "Environment variables template created at /tmp/s3-env-vars.txt"
}

# Main execution
main() {
    log "Starting S3 and backup setup for TroupeX..."
    
    check_prerequisites
    setup_media_bucket
    setup_backup_bucket
    create_iam_policy
    setup_cron_jobs
    generate_env_vars
    
    # Cleanup
    rm -f /tmp/cors.json /tmp/lifecycle.json /tmp/backup-lifecycle.json /tmp/mastodon-s3-policy.json
    
    log "Setup completed successfully!"
    log ""
    log "Next steps:"
    log "1. Create an IAM user and attach the TroupeXS3Policy"
    log "2. Generate access keys for the IAM user"
    log "3. Update your .env.production with the values from /tmp/s3-env-vars.txt"
    log "4. Install cron jobs: crontab /tmp/troupex-backup-cron"
    log "5. Make backup scripts executable: chmod +x scripts/*.sh"
    log "6. Test the setup with: ./scripts/test-s3-connection.sh"
}

# Run main function
main "$@"