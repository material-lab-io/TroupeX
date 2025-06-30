#!/bin/bash

echo "Stopping existing Rails processes..."
pkill -f "rails server" || true
pkill -f "puma.*3000" || true
sleep 2

cd /home/kanaba/troupex4/mastodon

export RAILS_ENV=development

echo "Starting Rails server in development mode..."
bundle exec rails server