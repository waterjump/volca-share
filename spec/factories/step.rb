# frozen_string_literal: true

def midi_range
  0..127
end

def one_to_sixteen
  1..16
end

FactoryBot.define do
  factory :step do
    index { one_to_sixteen.to_a.sample }
    note { midi_range.to_a.sample }
    step_mode { FFaker::Boolean.maybe }
    slide { FFaker::Boolean.maybe }
    active_step { FFaker::Boolean.maybe }
  end
end
