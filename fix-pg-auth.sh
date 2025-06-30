#!/bin/bash

echo "Fixing PostgreSQL authentication..."

# Update pg_hba.conf to allow local connections without password
echo "Please run these commands with sudo:"
echo ""
echo "1. Edit PostgreSQL authentication:"
echo "   sudo nano /etc/postgresql/*/main/pg_hba.conf"
echo ""
echo "2. Find the line that says:"
echo "   local   all             all                                     peer"
echo ""
echo "3. Change it to:"
echo "   local   all             all                                     trust"
echo ""
echo "4. Save and restart PostgreSQL:"
echo "   sudo systemctl restart postgresql"
echo ""
echo "Alternatively, set a password for the kanaba user in PostgreSQL:"
echo "   sudo -u postgres psql -c \"ALTER USER kanaba PASSWORD 'yourpassword';\""
echo "   Then add to .env.development.local: DB_PASS=yourpassword"