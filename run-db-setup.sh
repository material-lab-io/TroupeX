#!/bin/bash

echo "Creating and migrating TroupeX database..."

cd mastodon

# Create database
RAILS_ENV=development bundle exec rails db:create

# Run migrations
RAILS_ENV=development bundle exec rails db:migrate

# Seed database with initial data
RAILS_ENV=development bundle exec rails db:seed

echo "Database setup complete!"