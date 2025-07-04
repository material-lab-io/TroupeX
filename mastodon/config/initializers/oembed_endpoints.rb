# frozen_string_literal: true

# Pre-cache oEmbed endpoints for popular services that have large HTML pages
# This prevents FetchOEmbedService from failing when trying to discover endpoints

Rails.application.config.after_initialize do
  if Rails.env.production?
    # Define common oEmbed endpoints
    OEMBED_ENDPOINTS = {
      'youtube.com' => {
        endpoint: 'https://www.youtube.com/oembed?url={url}&format=json',
        format: :json
      },
      'www.youtube.com' => {
        endpoint: 'https://www.youtube.com/oembed?url={url}&format=json',
        format: :json
      },
      'youtu.be' => {
        endpoint: 'https://www.youtube.com/oembed?url={url}&format=json',
        format: :json
      },
      'vimeo.com' => {
        endpoint: 'https://vimeo.com/api/oembed.json?url={url}',
        format: :json
      },
      'twitter.com' => {
        endpoint: 'https://publish.twitter.com/oembed?url={url}&format=json',
        format: :json
      },
      'x.com' => {
        endpoint: 'https://publish.twitter.com/oembed?url={url}&format=json',
        format: :json
      },
      'instagram.com' => {
        endpoint: 'https://api.instagram.com/oembed?url={url}&format=json',
        format: :json
      },
      'www.instagram.com' => {
        endpoint: 'https://api.instagram.com/oembed?url={url}&format=json',
        format: :json
      },
      'tiktok.com' => {
        endpoint: 'https://www.tiktok.com/oembed?url={url}&format=json',
        format: :json
      },
      'www.tiktok.com' => {
        endpoint: 'https://www.tiktok.com/oembed?url={url}&format=json',
        format: :json
      },
      'soundcloud.com' => {
        endpoint: 'https://soundcloud.com/oembed?url={url}&format=json',
        format: :json
      },
      'spotify.com' => {
        endpoint: 'https://open.spotify.com/oembed?url={url}&format=json',
        format: :json
      },
      'open.spotify.com' => {
        endpoint: 'https://open.spotify.com/oembed?url={url}&format=json',
        format: :json
      }
    }.freeze

    # Cache endpoints on startup
    Rails.logger.info 'Pre-caching oEmbed endpoints...'
    
    OEMBED_ENDPOINTS.each do |domain, config|
      begin
        Rails.cache.write("oembed_endpoint:#{domain}", config, expires_in: 7.days)
        Rails.logger.info "Cached oEmbed endpoint for #{domain}"
      rescue => e
        Rails.logger.error "Failed to cache oEmbed endpoint for #{domain}: #{e.message}"
      end
    end
    
    Rails.logger.info 'oEmbed endpoint caching complete'
  end
end