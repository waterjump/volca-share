# frozen_string_literal: true

module Tags
  extend ActiveSupport::Concern

  included do
    before_validation :scrub_tags
  end

  private

  def scrub_tags
    tags.map! do |tag|
      return tag unless tag&.include?('#')

      tag.sub(/^#+/, '')
    end
  end
end
