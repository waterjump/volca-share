# frozen_string_literal: true

FactoryBot.define do
  factory :sequence do |_s|
    patch
    after(:build) do |sequence, _evaluator|
      16.times do |index|
        sequence.steps << build(:step, index: index + 1)
      end
    end
  end
end
