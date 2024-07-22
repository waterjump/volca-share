# frozen_string_literal: true

module ApplicationHelper
  def cookie_consent_given?
    cookies[:cookie_consent] == 'accepted'
  end
end
