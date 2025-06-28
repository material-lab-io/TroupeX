user = User.find_by(email: 'admin@troupex-dev.materiallab.io')
if user
  user.update!(confirmed_at: Time.now.utc, approved: true)
  puts 'Email confirmed and account approved!'
  puts "User: #{user.account.username}"
  puts "Email: #{user.email}"
  puts "Confirmed: #{user.confirmed?}"
  puts "Approved: #{user.approved?}"
else
  puts 'User not found'
end