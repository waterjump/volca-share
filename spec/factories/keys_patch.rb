# frozen_string_literal: true

FactoryBot.define do
  factory :keys_patch, class: Keys::Patch do |_p|
    name { FFaker::Lorem.characters(10) }
  end
end
