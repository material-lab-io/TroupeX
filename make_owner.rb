#!/usr/bin/env ruby

# Make the test user an Owner
user = User.find_by(email: 'test@example.com')
if user
  # Find the Owner role
  owner_role = UserRole.find_by(name: 'Owner')
  
  if owner_role
    user.role_id = owner_role.id
    user.save!
    puts "User promoted to Owner successfully!"
    puts "Email: #{user.email}"
    puts "Username: @#{user.account.username}"
    puts "Role: #{user.role.name}"
    puts "Permissions: #{user.role.permissions}"
  else
    puts "Owner role not found!"
  end
else
  puts "User not found!"
end