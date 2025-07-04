#!/bin/bash

echo "=== Production Link Preview Diagnostics ==="
echo

echo "1. Checking Sidekiq processes..."
docker exec troupex_sidekiq_1 ps aux | grep sidekiq || docker exec mastodon-sidekiq-1 ps aux | grep sidekiq
echo

echo "2. Checking Sidekiq logs for errors..."
docker logs --tail 50 troupex_sidekiq_1 2>&1 | grep -E "(ERROR|WARN|LinkCrawl)" || docker logs --tail 50 mastodon-sidekiq-1 2>&1 | grep -E "(ERROR|WARN|LinkCrawl)"
echo

echo "3. Checking Rails production logs..."
docker exec troupex_web_1 tail -n 50 log/production.log | grep -E "(LinkCrawl|preview_card|FetchLinkCard)" || docker exec mastodon-web-1 tail -n 50 log/production.log | grep -E "(LinkCrawl|preview_card|FetchLinkCard)"
echo

echo "4. Testing Rails console commands..."
docker exec -it troupex_web_1 bundle exec rails console -e production << 'EOF' || docker exec -it mastodon-web-1 bundle exec rails console -e production << 'EOF'
puts "Redis connected: #{Redis.current.ping rescue 'NO'}"
puts "Sidekiq queues: #{Sidekiq::Queue.all.map { |q| "#{q.name}(#{q.size})" }.join(', ')}"
puts "Recent preview cards: #{PreviewCard.order(created_at: :desc).limit(5).pluck(:url, :created_at).map { |u, t| "#{u} at #{t}" }.join("\n")}"

# Test creating a preview card
begin
  test_url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  card = PreviewCard.find_or_create_by(url: test_url) do |c|
    c.title = "Test Video"
    c.description = "Test description"
  end
  puts "Test preview card created: #{card.persisted?}"
rescue => e
  puts "Error creating preview card: #{e.message}"
end
exit
EOF

echo
echo "5. Checking environment variables..."
docker exec troupex_web_1 printenv | grep -E "(ALLOWED_PRIVATE_ADDRESSES|HTTP_PROXY|HTTPS_PROXY|NO_PROXY)" || docker exec mastodon-web-1 printenv | grep -E "(ALLOWED_PRIVATE_ADDRESSES|HTTP_PROXY|HTTPS_PROXY|NO_PROXY)"

echo
echo "6. Network connectivity test..."
docker exec troupex_web_1 curl -I https://www.youtube.com 2>&1 | head -5 || docker exec mastodon-web-1 curl -I https://www.youtube.com 2>&1 | head -5

echo
echo "Done!"