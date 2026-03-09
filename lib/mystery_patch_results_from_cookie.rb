# frozen_string_literal: true

class MysteryPatchResultsFromCookie
  DEFAULT_TEXT = 'New'

  def initialize(raw_cookie)
    @raw_cookie = raw_cookie
  end

  def total_score
    data.dig(:results, :total_score)
  end

  def mystery_patch_id
    data.dig(:mysteryPatchId)
  end

  def callout_text
    return DEFAULT_TEXT unless freshest? && total_score

    "#{total_score}%"
  end

  def freshest?
    mystery_patch_id == most_recent_mystery_patch_id
  end

  private

  attr_reader :raw_cookie

  def most_recent_mystery_patch_id
    MysteryPatch.only(:id).desc(:created_at).limit(1).pick(:id).to_s
  end

  def data
    @data ||= JSON.parse(raw_cookie.to_s).deep_symbolize_keys!
  rescue JSON::ParserError
    {}
  end
end
