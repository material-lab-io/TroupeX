#!/bin/bash

# Quick fix script for link preview issues in production
# Run this on the production server after SSHing in

echo "=== Applying Link Preview Fixes ==="
echo

echo "1. Restarting Sidekiq to ensure it picks up all changes..."
docker-compose -f docker-compose.production.yml restart sidekiq
echo "Waiting for Sidekiq to start..."
sleep 10
echo

echo "2. Checking if Sidekiq is running properly..."
docker ps | grep sidekiq
echo

echo "3. Testing network connectivity from Sidekiq container..."
docker exec troupex-sidekiq-1 curl -s -o /dev/null -w "YouTube HTTPS test: %{http_code}\n" https://www.youtube.com || echo "Failed to connect"
echo

echo "4. Manually processing any pending link preview jobs..."
docker exec troupex-sidekiq-1 bundle exec rails runner -e production "
require 'sidekiq/api'

# Process any stuck jobs in the pull queue
queue = Sidekiq::Queue.new('pull')
if queue.size > 0
  puts \"Found #{queue.size} jobs in pull queue, processing...\"
  queue.each do |job|
    if job.klass == 'LinkCrawlWorker'
      puts \"Processing LinkCrawlWorker for status #{job.args.first}\"
      begin
        job.delete
        LinkCrawlWorker.new.perform(job.args.first)
      rescue => e
        puts \"Error: #{e.message}\"
      end
    end
  end
else
  puts 'No jobs in pull queue'
end

# Clear any dead link crawl jobs
dead = Sidekiq::DeadSet.new
link_dead = dead.select { |job| job.klass == 'LinkCrawlWorker' }
if link_dead.any?
  puts \"Clearing #{link_dead.size} dead LinkCrawlWorker jobs\"
  link_dead.each(&:delete)
end
"
echo

echo "5. Creating a test post to verify link previews work..."
docker exec troupex-sidekiq-1 bundle exec rails runner -e production "
account = Account.find_by(username: 'admin') || Account.first
if account
  status = Status.create!(
    account: account,
    text: 'Testing link previews: https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    visibility: 'public'
  )
  
  puts \"Created test status ##{status.id}\"
  
  # Process immediately
  LinkCrawlWorker.new.perform(status.id)
  
  status.reload
  if status.preview_cards.any?
    card = status.preview_cards.first
    puts \"SUCCESS! Preview card created:\"
    puts \"  Title: #{card.title}\"
    puts \"  URL: #{card.url}\"
  else
    puts \"FAILED: No preview card created\"
  end
else
  puts 'No account found for testing'
end
"

echo
echo "Done! Link previews should now be working."
echo "Try creating a new post with a YouTube URL to verify."