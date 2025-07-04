#!/bin/bash

# Script to debug link preview issues in production
# Run this on the production server

echo "=== Production Link Preview Diagnostics ==="
echo "Run this script on your production server after SSHing in"
echo

echo "1. Check if new Docker images are being used:"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.CreatedAt}}"
echo

echo "2. Check Sidekiq logs for link preview errors:"
docker logs troupex-sidekiq-1 --tail 100 2>&1 | grep -E "LinkCrawlWorker|FetchLinkCardService|Error fetching link"
echo

echo "3. Test SSL certificates in containers:"
docker exec troupex-sidekiq-1 ls -la /etc/ssl/certs/ | head -5
docker exec troupex-sidekiq-1 curl -I https://www.youtube.com 2>&1 | head -5
echo

echo "4. Check if Sidekiq is processing the pull queue:"
docker exec troupex-sidekiq-1 bundle exec rails runner -e production "
require 'sidekiq/api'
queues = Sidekiq::Queue.all
queues.each do |queue|
  puts \"Queue '#{queue.name}': #{queue.size} jobs\"
end

# Check for dead jobs
dead = Sidekiq::DeadSet.new
link_dead = dead.select { |job| job.klass == 'LinkCrawlWorker' }
if link_dead.any?
  puts \"\nDead LinkCrawlWorker jobs:\"
  link_dead.first(3).each do |job|
    puts \"  Error: #{job['error_message']}\"
  end
end
"
echo

echo "5. Test creating a preview card manually:"
docker exec -it troupex-web-1 bundle exec rails console -e production << 'EOF'
# Find a recent status with a URL
status = Status.where("text LIKE '%http%'").order(created_at: :desc).first
if status
  puts "Testing with status ##{status.id}: #{status.text.truncate(50)}"
  
  # Try to fetch card
  service = FetchLinkCardService.new
  result = service.call(status)
  
  status.reload
  if status.preview_cards.any?
    puts "Preview card exists: #{status.preview_cards.first.title}"
  else
    puts "No preview card created"
  end
else
  puts "No status with URL found"
end
exit
EOF
echo

echo "6. Check recent preview cards:"
docker exec troupex-web-1 bundle exec rails runner -e production "
cards = PreviewCard.order(created_at: :desc).limit(5)
if cards.any?
  puts 'Recent preview cards:'
  cards.each do |card|
    puts \"  #{card.created_at}: #{card.url.truncate(50)} - #{card.title.try(:truncate, 30)}\"
  end
else
  puts 'No preview cards found'
end
"

echo
echo "Done! If you see SSL/network errors, the containers may need to be restarted:"
echo "  docker-compose -f docker-compose.production.yml restart sidekiq"