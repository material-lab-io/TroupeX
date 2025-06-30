#!/usr/bin/env ruby
# Create admin user for Mastodon

# Set up the account
account = Account.find_or_initialize_by(username: 'troupeadmin')
account.display_name = 'Administrator'
account.save!

# Set up the user
user = User.find_or_initialize_by(email: 'admin@troupex.local')
user.password = 'TroupeAdmin123!'
user.password_confirmation = 'TroupeAdmin123!'
user.confirmed_at = Time.now
user.approved = true
user.account = account
user.agreement = true  # Accept service agreement
user.save!

# Make the user an Owner (admin)
owner_role = UserRole.find_by(name: 'Owner')
if owner_role
  user.role = owner_role
  user.save!
else
  puts "Owner role not found, making user a simple admin"
  user.admin = true
  user.save!
end

puts "Admin account created successfully!"
puts "Username: troupeadmin"
puts "Email: admin@troupex.local"
puts "Password: TroupeAdmin123!"