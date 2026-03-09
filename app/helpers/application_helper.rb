# frozen_string_literal: true

module ApplicationHelper
  def cookie_consent_given?
    cookies[:cookie_consent] == 'accepted'
  end

  def format_date(date)
    date&.strftime('%B %-d, %Y')
  end

  def mystery_patch_feature_enabled?
    ENV['FEATURE_ENABLED_MYSTERY_PATCH'] == 'true'
  end

  def mystery_patch_cookie_data
    # NOTE: Helpers are scoped to single request, so memoization here will not
    #       affect other requests or users.
    @mystery_patch_cookie_data ||=
      MysteryPatchResultsFromCookie.new(cookies[:resultsData])
  end

  def mystery_patch_callout_text
    mystery_patch_cookie_data.callout_text
  end

  def emphasize_new_mystery_patch?
    !mystery_patch_cookie_data.freshest?
  end

  def mystery_patch_callout_class
    score = mystery_patch_cookie_data.total_score

    case score
    when 80.0..Float::INFINITY
      :'green-callout'
    when 50.0..80.0
      :'yellow-callout'
    when -Float::INFINITY..50.0
      :'red-callout'
    end
  end
end
