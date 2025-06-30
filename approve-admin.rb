#!/usr/bin/env ruby

user = User.find_by(email: 'admin@troupex.local')
if user
  user.approved = true
  user.save!
  puts "Account approved successfully!"
  puts "User can now login with:"
  puts "Email: #{user.email}"
  puts "Password: TroupeAdmin123!"
else
  puts "User not found!"
end