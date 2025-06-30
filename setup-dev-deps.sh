#!/bin/bash

echo "Setting up Mastodon development dependencies..."

# Start PostgreSQL and Redis
echo "Starting PostgreSQL and Redis..."
sudo systemctl start postgresql redis

# Check if services are running
if systemctl is-active --quiet postgresql; then
    echo "✅ PostgreSQL is running"
else
    echo "❌ PostgreSQL failed to start"
    exit 1
fi

if systemctl is-active --quiet redis; then
    echo "✅ Redis is running"
else
    echo "❌ Redis failed to start"
    exit 1
fi

# Create PostgreSQL user and database
echo "Setting up PostgreSQL for development..."
sudo -u postgres psql <<EOF
-- Create user if not exists
DO
\$\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE  rolname = 'kanaba') THEN
      CREATE ROLE kanaba LOGIN SUPERUSER;
   END IF;
END
\$\$;

-- Create database if not exists
SELECT 'CREATE DATABASE mastodon_development OWNER kanaba'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'mastodon_development')\gexec

SELECT 'CREATE DATABASE mastodon_test OWNER kanaba'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'mastodon_test')\gexec
EOF

echo "✅ PostgreSQL setup complete"

echo ""
echo "Next steps:"
echo "1. Run this script with: ./setup-dev-deps.sh"
echo "2. Then run: cd mastodon && bundle exec rails db:migrate"
echo "3. Start Rails: cd mastodon && bundle exec rails server"