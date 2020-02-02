# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    username { FFaker::Internet.user_name[0..19] }
    email { FFaker::Internet.email }
    password { Devise.friendly_token.first(8) }
    slug { username.parameterize }
  end
end
