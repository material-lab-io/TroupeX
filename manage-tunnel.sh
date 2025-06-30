#!/bin/bash

case "$1" in
    start)
        echo "Starting TroupeX tunnel..."
        # Kill any existing tunnel
        pkill -f "cloudflared.*troupex-preprod" 2>/dev/null
        sleep 2
        
        # Start tunnel with nohup
        nohup cloudflared tunnel --config ~/.cloudflared/troupex-preprod-config.yml run troupex-preprod > ~/troupex-tunnel.log 2>&1 &
        echo $! > ~/troupex-tunnel.pid
        
        sleep 3
        if ps -p $(cat ~/troupex-tunnel.pid) > /dev/null; then
            echo "✅ Tunnel started successfully!"
            echo "PID: $(cat ~/troupex-tunnel.pid)"
            echo "Logs: tail -f ~/troupex-tunnel.log"
        else
            echo "❌ Failed to start tunnel"
            tail -20 ~/troupex-tunnel.log
        fi
        ;;
        
    stop)
        echo "Stopping TroupeX tunnel..."
        if [ -f ~/troupex-tunnel.pid ]; then
            kill $(cat ~/troupex-tunnel.pid) 2>/dev/null
            rm ~/troupex-tunnel.pid
            echo "✅ Tunnel stopped"
        else
            pkill -f "cloudflared.*troupex-preprod"
            echo "✅ Tunnel processes killed"
        fi
        ;;
        
    restart)
        $0 stop
        sleep 2
        $0 start
        ;;
        
    status)
        if [ -f ~/troupex-tunnel.pid ] && ps -p $(cat ~/troupex-tunnel.pid) > /dev/null; then
            echo "✅ Tunnel is running (PID: $(cat ~/troupex-tunnel.pid))"
            echo ""
            echo "Recent logs:"
            tail -10 ~/troupex-tunnel.log
        else
            echo "❌ Tunnel is not running"
            # Check if any cloudflared process is running
            if pgrep -f "cloudflared.*troupex-preprod" > /dev/null; then
                echo "⚠️  Found cloudflared process but no PID file"
                ps aux | grep cloudflared | grep troupex-preprod | grep -v grep
            fi
        fi
        ;;
        
    logs)
        tail -f ~/troupex-tunnel.log
        ;;
        
    test)
        echo "Testing tunnel connectivity..."
        # Test DNS
        echo -n "DNS Resolution: "
        if host troupex-preprod.materiallab.io > /dev/null 2>&1; then
            echo "✅ OK"
        else
            echo "❌ Failed"
        fi
        
        # Test HTTPS
        echo -n "HTTPS Access: "
        if curl -s -o /dev/null -w "%{http_code}" https://troupex-preprod.materiallab.io/ | grep -q "200\|301\|302"; then
            echo "✅ OK"
        else
            echo "❌ Failed ($(curl -s -o /dev/null -w "%{http_code}" https://troupex-preprod.materiallab.io/))"
        fi
        
        # Test local service
        echo -n "Local Service: "
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:3100/health | grep -q "200"; then
            echo "✅ OK"
        else
            echo "❌ Failed"
        fi
        ;;
        
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|test}"
        exit 1
        ;;
esac