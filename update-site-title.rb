#!/usr/bin/env ruby

# Update the site title to TroupeX
Setting.site_title = 'TroupeX'
puts "Site title updated to: #{Setting.site_title}"

# Clear Rails cache to ensure changes take effect
Rails.cache.clear
puts "Cache cleared successfully!"