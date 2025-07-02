#!/usr/bin/env ruby

# Create a test user account
user = User.find_or_initialize_by(email: 'test@example.com')
user.account ||= user.build_account
user.account.username = 'testuser'
user.account.display_name = 'Test User'
user.password = 'password123'
user.password_confirmation = 'password123'
user.confirmed_at = Time.now.utc
user.approved = true
user.disabled = false
user.agreement = true
user.save!

puts "User created successfully!"
puts "Email: test@example.com"
puts "Password: password123"
puts "Username: @testuser"