#!/usr/bin/env ruby

# Find the admin user
admin = User.find_by(email: 'admin@troupex.local')
if admin.nil?
  puts "Admin user not found! Looking for other admin users..."
  admin = User.joins(:user_role).where(user_roles: {name: 'Owner'}).first
  if admin.nil?
    puts "No admin users found!"
    exit
  end
end

puts "Found admin user: #{admin.account.username}"

# Get all local accounts except the admin's own
other_accounts = Account.local.where.not(id: admin.account_id)

puts "Found #{other_accounts.count} other local accounts"

# Follow each account
followed_count = 0
other_accounts.find_each do |account|
  begin
    # Skip if already following
    unless admin.account.following?(account)
      admin.account.follow!(account)
      followed_count += 1
      puts "Followed @#{account.username}"
    else
      puts "Already following @#{account.username}"
    end
  rescue => e
    puts "Error following @#{account.username}: #{e.message}"
  end
end

puts "\nFollowed #{followed_count} new accounts!"
puts "Total following: #{admin.account.following_count}"

# Create some sample posts if needed
if admin.account.statuses.count == 0
  puts "\nCreating a welcome post..."
  PostStatusService.new.call(
    admin.account,
    text: "Welcome to TroupeX! 🚀 Just set up my account and ready to connect with everyone. #TroupeX #Welcome",
    visibility: :public
  )
  puts "Created welcome post!"
end

puts "\nRefreshing home timeline..."
FeedManager.instance.populate_home(admin.account)

puts "\nDone! Your home timeline should now show posts from the accounts you follow."
puts "You may need to refresh your browser to see the updates."