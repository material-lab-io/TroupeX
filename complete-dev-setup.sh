#!/bin/bash

cd /home/kanaba/troupex4/mastodon

# Set Rails environment
export RAILS_ENV=development

echo "🔧 Running database migrations..."
bundle exec rails db:migrate

echo "🌱 Seeding database with sample data..."
bundle exec rails db:seed

echo "👤 Creating admin user..."
bundle exec rails mastodon:accounts:create USERNAME=admin EMAIL=admin@localhost ROLE=Owner --confirmed || echo "Admin user may already exist"

echo ""
echo "✅ Setup complete!"
echo ""
echo "To start the full Mastodon development environment:"
echo "1. Make sure Vite is running (it should be): yarn dev"
echo "2. In another terminal: bundle exec rails server"
echo "3. Access Mastodon at: http://localhost:3000"
echo ""
echo "With HMR enabled, any changes to:"
echo "- app/javascript/styles/ - will hot reload"
echo "- app/javascript/mastodon/ - will hot reload React components"