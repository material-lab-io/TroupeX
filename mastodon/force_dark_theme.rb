#!/usr/bin/env ruby
# Script to force all users to use dark theme

require_relative 'config/environment'

puts "Updating all users to use dark theme..."

# Update all users who have a theme preference set
User.find_each do |user|
  if user.settings['theme'].present? && user.settings['theme'] != 'default'
    user.settings['theme'] = 'default'
    user.save!
    print "."
  end
end

# Update the global setting
Setting.theme = 'default'

puts "\nDone! All users are now using the dark theme."
puts "You may need to restart the web service for changes to take effect."