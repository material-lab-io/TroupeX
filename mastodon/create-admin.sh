#!/bin/bash

echo "Creating Mastodon admin account..."
echo "=================================="
echo ""

# Generate a random password
PASSWORD=$(openssl rand -base64 12)

# Create the account using Rails console
docker compose -f docker-compose.dev.yml exec -T web rails runner "
  account = Account.create!(username: 'showcase_admin')
  user = User.create!(
    email: 'admin@troupex-dev.materiallab.io',
    password: '$PASSWORD',
    password_confirmation: '$PASSWORD',
    confirmed_at: Time.now.utc,
    approved: true,
    account: account,
    agreement: true
  )
  user.update!(role: UserRole.find_by(name: 'Admin') || UserRole.first)
  puts 'Admin account created successfully!'
  puts 'Email: admin@troupex-dev.materiallab.io'
  puts 'Password: $PASSWORD'
"

echo ""
echo "Save these credentials securely!"