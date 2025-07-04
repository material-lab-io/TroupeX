# Fix Link Previews in Production

## Problem
URL previews (link cards) work in development but not in production.

## Common Causes & Solutions

### 1. Check Sidekiq is processing the 'pull' queue

The LinkCrawlWorker runs in the 'pull' queue. Make sure Sidekiq is processing it:

```bash
# SSH into your production server
ssh deploy@159.89.169.132

# Check if Sidekiq is running and processing queues
docker exec mastodon-sidekiq-1 ps aux | grep sidekiq

# Check Sidekiq logs
docker logs --tail 100 mastodon-sidekiq-1 | grep -i "pull\|link"

# Check queues in Rails console
docker exec -it mastodon-web-1 bundle exec rails console -e production
> Sidekiq::Queue.all.map { |q| [q.name, q.size] }
> exit
```

### 2. Network Access from Docker Container

The Docker container needs to access external URLs. Check:

```bash
# Test network access from the container
docker exec mastodon-web-1 curl -I https://www.youtube.com

# If this fails, you may need to configure Docker networking or proxy settings
```

### 3. Environment Variables

Add these to your `.env.production` if not present:

```env
# Allow Mastodon to fetch remote resources
ALLOWED_PRIVATE_ADDRESSES=

# If behind a proxy, configure proxy settings
# HTTP_PROXY=http://your-proxy:port
# HTTPS_PROXY=http://your-proxy:port
# NO_PROXY=localhost,127.0.0.1

# Increase timeout for slow servers (optional)
# FETCH_TIMEOUT=30
```

### 4. Quick Fix - Restart Services

Sometimes a simple restart helps:

```bash
# Restart Sidekiq to ensure it's processing all queues
docker-compose -f docker-compose.production.yml restart sidekiq

# Or restart all services
docker-compose -f docker-compose.production.yml restart
```

### 5. Manual Test

Test link preview fetching manually:

```bash
docker exec -it mastodon-web-1 bundle exec rails console -e production

# Find a recent status with a URL
status = Status.where("text LIKE '%http%'").last

# Try to fetch its link card manually
FetchLinkCardService.new.call(status)

# Check if it worked
status.reload.preview_cards
```

### 6. Debug Network Issues

If external requests are blocked:

```bash
# Check iptables rules
sudo iptables -L -n

# Check if Docker daemon has DNS issues
docker exec mastodon-web-1 nslookup youtube.com

# Check container's resolv.conf
docker exec mastodon-web-1 cat /etc/resolv.conf
```

### 7. DigitalOcean Specific

If hosted on DigitalOcean, check:
- Firewall rules allow outbound HTTPS (port 443)
- No IP blocking rules preventing container access
- DNS resolution works correctly

## Verification

After applying fixes, test by:

1. Creating a new post with a YouTube URL
2. Wait 30-60 seconds for the preview to generate
3. Check Sidekiq logs for any errors
4. Refresh the page to see if the preview appears

## Production Deployment Note

The issue might be that the production Docker image doesn't have proper network configuration. You may need to rebuild with:

```yaml
# In docker-compose.production.yml, add to web and sidekiq services:
dns:
  - 8.8.8.8
  - 8.8.4.4
```