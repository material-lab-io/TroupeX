#!/usr/bin/env ruby
# Debug script to test link preview fetching in production

require_relative 'mastodon/config/environment'

puts "=== Link Preview Debug Script ==="
puts "Environment: #{Rails.env}"
puts "Redis connected: #{Redis.current.ping == 'PONG'}"
puts

# Check if Sidekiq is processing the pull queue
puts "Checking Sidekiq queues..."
queues = Sidekiq::Queue.all
queues.each do |queue|
  puts "Queue '#{queue.name}': #{queue.size} jobs"
end
puts

# Check for failed jobs
puts "Checking failed jobs..."
failed_jobs = Sidekiq::DeadSet.new
puts "Failed jobs: #{failed_jobs.size}"
if failed_jobs.size > 0
  puts "Recent failed jobs:"
  failed_jobs.first(5).each do |job|
    puts "  - #{job['class']} failed at #{job['failed_at']}: #{job['error_message']}"
  end
end
puts

# Test fetching a URL preview
test_url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
puts "Testing URL preview fetch for: #{test_url}"

# Create a test status
begin
  account = Account.find_by(username: 'admin') || Account.first
  if account.nil?
    puts "ERROR: No account found to test with"
    exit 1
  end
  
  puts "Using account: @#{account.username}"
  
  # Create a test status with a URL
  status = Status.create!(
    account: account,
    text: "Test status with URL: #{test_url}",
    visibility: 'public'
  )
  
  puts "Created status ##{status.id}"
  
  # Try to fetch the link card directly
  puts "Attempting to fetch link card..."
  service = FetchLinkCardService.new
  result = service.call(status)
  
  # Check if preview card was created
  status.reload
  if status.preview_cards.any?
    card = status.preview_cards.first
    puts "SUCCESS: Preview card created!"
    puts "  Title: #{card.title}"
    puts "  Description: #{card.description}"
    puts "  URL: #{card.url}"
    puts "  Provider: #{card.provider_name}"
  else
    puts "FAILED: No preview card created"
    
    # Check if the job was queued
    job_queued = Sidekiq::Queue.new('pull').any? { |job| 
      job.klass == 'LinkCrawlWorker' && job.args.include?(status.id) 
    }
    puts "LinkCrawlWorker queued: #{job_queued}"
  end
  
  # Clean up
  status.destroy
  puts "\nTest status cleaned up"
  
rescue => e
  puts "ERROR: #{e.class}: #{e.message}"
  puts e.backtrace.first(5)
end

puts "\n=== Additional Checks ==="

# Check HTTP request capability
puts "Testing HTTP requests..."
begin
  require 'net/http'
  uri = URI('https://www.google.com')
  response = Net::HTTP.get_response(uri)
  puts "HTTP request test: #{response.code} #{response.message}"
rescue => e
  puts "HTTP request failed: #{e.message}"
end

# Check if there are any network restrictions
puts "\nChecking allowed hosts..."
allowed_hosts = Rails.configuration.x.access_to_hidden_service
puts "Access to hidden service: #{allowed_hosts}"

puts "\nDone!"