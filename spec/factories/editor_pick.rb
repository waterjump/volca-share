# frozen_string_literal: true

FactoryBot.define do
  factory :editor_pick do
    list_key { 'default' }
    association :pickable, factory: :patch

    factory :keys_editor_pick do
      association :pickable, factory: :keys_patch
    end
  end
end
