#!/usr/bin/env ruby

# Check user role and permissions
user = User.find_by(email: 'test@example.com')
if user
  puts "User found: #{user.email}"
  puts "Username: @#{user.account.username}"
  puts "Role ID: #{user.role_id || 'None'}"
  
  if user.role
    puts "Role Name: #{user.role.name}"
    puts "Role Permissions: #{user.role.permissions}"
    puts "Is Admin?: #{user.role.everyone? ? 'No' : 'Yes'}"
  else
    puts "User has no role assigned (default user)"
  end
  
  # Check available roles
  puts "\nAvailable roles:"
  UserRole.all.each do |role|
    puts "- #{role.name} (ID: #{role.id})"
  end
else
  puts "User not found!"
end