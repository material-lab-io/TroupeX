# TroupeX Troubleshooting Guide

## Common Issues and Solutions

### Installation Issues

#### Ruby Version Conflicts
**Problem:** Wrong Ruby version installed
```bash
# Error: Your Ruby version is X, but your Gemfile specified Y
```

**Solution:**
```bash
rbenv install 3.4.4
rbenv global 3.4.4
rbenv rehash
gem install bundler
```

#### Node.js/Yarn Issues
**Problem:** Yarn commands fail
```bash
# Error: This project's package.json defines "packageManager": "yarn@4.9.2"
```

**Solution:**
```bash
corepack enable
corepack prepare yarn@4.9.2 --activate
```

### Development Issues

#### Assets Not Updating
**Problem:** Changes to CSS/JS not reflecting

**Solution:**
```bash
# Clear cache and rebuild
cd mastodon
rm -rf tmp/cache
yarn build:development
bin/dev
```

#### Hot Reload Not Working
**Problem:** Vite HMR not updating

**Solution:**
```bash
# Use the hot reload script
./troupe-hot-reload.sh

# Or manually fix Vite config
cd mastodon
yarn dev --host 0.0.0.0
```

### Database Issues

#### Migration Failures
**Problem:** Database migrations fail

**Solution:**
```bash
# Check migration status
cd mastodon
bundle exec rails db:migrate:status

# Rollback and retry
bundle exec rails db:rollback
bundle exec rails db:migrate

# Reset if needed (WARNING: Data loss)
bundle exec rails db:reset
```

#### Connection Errors
**Problem:** Can't connect to PostgreSQL

**Solution:**
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Check connection
psql -U postgres -h localhost

# Fix authentication
sudo -u postgres psql
ALTER USER mastodon PASSWORD 'newpassword';
```

### Docker Issues

#### Container Won't Start
**Problem:** Docker containers failing

**Solution:**
```bash
# Check logs
docker-compose logs web
docker-compose logs sidekiq

# Rebuild containers
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

#### Permission Errors
**Problem:** File permission issues in containers

**Solution:**
```bash
# Fix permissions
sudo chown -R 991:991 mastodon/public/system
sudo chmod -R 755 mastodon/public

# Or use the fix script
./fix-all-upload-permissions.sh
```

### Production Issues

#### 500 Internal Server Error
**Problem:** Application returns 500 errors

**Solution:**
```bash
# Check Rails logs
tail -f mastodon/log/production.log

# Use debug script
./debug-500-error.sh

# Common fixes
cd mastodon
RAILS_ENV=production bundle exec rails assets:precompile
RAILS_ENV=production bundle exec rails db:migrate
```

#### Streaming Not Working
**Problem:** Real-time updates not appearing

**Solution:**
```bash
# Check streaming service
docker-compose logs streaming

# Verify WebSocket connection
curl -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Key: x3JJHMbDL1EzLkh9GBhXDw==" \
  -H "Sec-WebSocket-Version: 13" \
  https://your-domain.com/api/v1/streaming

# Restart streaming
docker-compose restart streaming
```

#### Media Upload Failures
**Problem:** Can't upload images/videos

**Solution:**
```bash
# Check disk space
df -h

# Fix permissions
./fix-upload-permissions.sh

# Check S3 configuration (if using)
cd mastodon
bundle exec rails console
> Rails.configuration.x.s3_enabled
```

### Performance Issues

#### Slow Timeline Loading
**Problem:** Feeds load slowly

**Solution:**
```bash
# Optimize database
cd mastodon
bundle exec rails db:analyze

# Increase cache
# In .env.production
REDIS_CACHE_MEGABYTES=512

# Add indexes
bundle exec rails generate migration AddIndexToStatuses
```

#### High Memory Usage
**Problem:** Application using too much RAM

**Solution:**
```bash
# Tune Sidekiq workers
# In docker-compose.yml
command: bundle exec sidekiq -c 10  # Reduce from 25

# Tune Puma
# In config/puma.rb
workers 2  # Reduce workers
threads 5, 5  # Reduce threads
```

### Debugging Tools

#### Rails Console
```bash
# Access console
cd mastodon
bundle exec rails console

# Useful commands
User.find_by(email: 'admin@example.com')
Status.where(created_at: 1.day.ago..Time.current).count
Account.where(suspended: true).count
```

#### Database Queries
```bash
# Connect to database
cd mastodon
bundle exec rails dbconsole

# Check slow queries
SELECT query, calls, mean_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

#### Redis Debugging
```bash
# Connect to Redis
redis-cli

# Check memory usage
INFO memory

# Monitor commands
MONITOR
```

### Logs Location

| Service | Log Location |
|---------|--------------|
| Rails | `mastodon/log/production.log` |
| Sidekiq | `mastodon/log/sidekiq.log` |
| Nginx | `/var/log/nginx/error.log` |
| PostgreSQL | `/var/log/postgresql/*.log` |
| Docker | `docker-compose logs [service]` |

### Getting Help

1. Check existing [GitHub Issues](https://github.com/material-lab-io/TroupeX/issues)
2. Search [Mastodon Discourse](https://discourse.joinmastodon.org/)
3. Review [Stack Overflow](https://stackoverflow.com/questions/tagged/mastodon)
4. Contact support at support@materiallab.io

---

Remember to always backup your data before attempting fixes!