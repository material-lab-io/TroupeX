# frozen_string_literal: true

module ThemeHelper
  def theme_style_tags(theme)
    # Force dark theme only
    vite_stylesheet_tag 'themes/default', type: :virtual, media: 'all', crossorigin: 'anonymous'
  end

  def theme_color_tags(theme)
    # Force dark theme color
    tag.meta name: 'theme-color', content: Themes::THEME_COLORS[:dark]
  end

  def custom_stylesheet
    if active_custom_stylesheet.present?
      stylesheet_link_tag(
        custom_css_path(active_custom_stylesheet),
        host: root_url,
        media: :all,
        skip_pipeline: true
      )
    end
  end

  private

  def active_custom_stylesheet
    if cached_custom_css_digest.present?
      [:custom, cached_custom_css_digest.to_s.first(8)]
        .compact_blank
        .join('-')
    end
  end

  def cached_custom_css_digest
    Rails.cache.fetch(:setting_digest_custom_css) do
      Setting.custom_css&.then { |content| Digest::SHA256.hexdigest(content) }
    end
  end

  def theme_color_for(theme)
    theme == 'mastodon-light' ? Themes::THEME_COLORS[:light] : Themes::THEME_COLORS[:dark]
  end
end
