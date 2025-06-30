#!/bin/bash
# Test S3/DigitalOcean Spaces connection

echo "Testing DigitalOcean Spaces connection..."

# Test with AWS CLI
echo "Testing with AWS CLI..."
aws s3 ls s3://troupex-ugc \
  --endpoint-url https://blr1.digitaloceanspaces.com \
  --region blr1 \
  2>&1 | head -10

if [ $? -eq 0 ]; then
    echo "✅ AWS CLI connection successful"
else
    echo "❌ AWS CLI connection failed"
fi

# Test from within container
echo -e "\nTesting from Mastodon container..."
docker exec mastodon_web_1 bundle exec rails runner "
  require 'aws-sdk-s3'
  
  begin
    puts 'Creating S3 client...'
    client = Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      endpoint: ENV['S3_ENDPOINT'],
      region: ENV['S3_REGION']
    )
    
    puts 'Listing objects in bucket...'
    resp = client.list_objects_v2(bucket: ENV['S3_BUCKET'], max_keys: 5)
    
    puts \"✅ Connection successful!\"
    puts \"Bucket: #{ENV['S3_BUCKET']}\"
    puts \"Objects in bucket: #{resp.contents.size}\"
    resp.contents.first(5).each do |obj|
      puts \"  - #{obj.key} (#{obj.size} bytes)\"
    end
  rescue => e
    puts \"❌ Connection failed: #{e.message}\"
  end
"

echo -e "\nConfiguration summary:"
docker exec mastodon_web_1 bundle exec rails runner "
  puts \"S3_ENABLED: #{ENV['S3_ENABLED']}\"
  puts \"S3_BUCKET: #{ENV['S3_BUCKET']}\"
  puts \"S3_ENDPOINT: #{ENV['S3_ENDPOINT']}\"
  puts \"S3_ALIAS_HOST: #{ENV['S3_ALIAS_HOST']}\"
  puts \"Paperclip storage: #{Paperclip::Attachment.default_options[:storage]}\"
"