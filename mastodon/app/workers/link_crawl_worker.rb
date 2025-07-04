# frozen_string_literal: true

class LinkCrawlWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull', retry: 0

  def perform(status_id)
    Rails.logger.info "LinkCrawlWorker: Processing status #{status_id}"
    status = Status.find(status_id)
    Rails.logger.info "LinkCrawlWorker: Found status with text: #{status.text.truncate(100)}"
    
    result = FetchLinkCardService.new.call(status)
    Rails.logger.info "LinkCrawlWorker: Completed for status #{status_id}, result: #{result.inspect}"
  rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordNotUnique => e
    Rails.logger.error "LinkCrawlWorker: Error for status #{status_id}: #{e.class} - #{e.message}"
    true
  end
end
