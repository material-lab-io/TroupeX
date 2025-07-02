#!/usr/bin/env ruby

# Approve the test user
user = User.find_by(email: 'test@example.com')
if user
  user.approved = true
  user.save!
  puts "User approved successfully!"
  puts "Email: #{user.email}"
  puts "Username: @#{user.account.username}"
else
  puts "User not found!"
end