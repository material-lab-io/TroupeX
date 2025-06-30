# TroupeX Pre-Production Access

## 🌐 Access URL
https://troupex-preprod.materiallab.io

## 🔐 Admin Login
- **Email:** troupeadmin@localhost
- **Password:** <your-admin-password>

## 🚀 Quick Commands

### Check Status
```bash
./manage-tunnel.sh status
docker-compose -f mastodon/docker-compose.dev.yml ps
```

### Restart Tunnel (if needed)
```bash
./manage-tunnel.sh restart
```

### View Logs
```bash
# Tunnel logs
./manage-tunnel.sh logs

# Mastodon logs
docker-compose -f mastodon/docker-compose.dev.yml logs -f
```

### Stop Everything
```bash
./manage-tunnel.sh stop
docker-compose -f mastodon/docker-compose.dev.yml down
```

### Start Everything
```bash
docker-compose -f mastodon/docker-compose.dev.yml up -d
./manage-tunnel.sh start
```

## 🔧 Troubleshooting

If you can't access the site:
1. Clear browser cache and try incognito mode
2. Try a different browser
3. Check tunnel status: `./manage-tunnel.sh status`
4. Restart tunnel: `./manage-tunnel.sh restart`
5. Test connectivity: `./manage-tunnel.sh test`

The tunnel is confirmed working and will stay running in the background!