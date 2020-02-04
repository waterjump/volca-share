# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Keys::Patch do
  describe 'fields' do
    it { is_expected.to have_field(:name).of_type(String) }

    it do
      is_expected.to(
        have_field(:secret)
          .of_type(Mongoid::Boolean)
          .with_default_value_of(false)
      )
    end

    it { is_expected.to have_field(:notes).of_type(String) }
    it { is_expected.to have_field(:slug).of_type(String) }

    it do
      is_expected.to(
        have_field(:voice).of_type(Integer).with_default_value_of(57)
      )
    end

    it do
      is_expected.to(
        have_field(:octave).of_type(Integer).with_default_value_of(57)
      )
    end

    it do
      is_expected.to(
        have_field(:detune).of_type(Integer).with_default_value_of(0)
      )
    end

    it do
      is_expected.to(
        have_field(:portamento).of_type(Integer).with_default_value_of(0)
      )
    end

    it do
      is_expected.to(
        have_field(:vco_eg_int).of_type(Integer).with_default_value_of(0)
      )
    end

    it do
      is_expected.to(
        have_field(:cutoff).of_type(Integer).with_default_value_of(63)
      )
    end

    it do
      is_expected.to(
        have_field(:peak).of_type(Integer).with_default_value_of(0)
      )
    end

    it do
      is_expected.to(
        have_field(:vcf_eg_int).of_type(Integer).with_default_value_of(0)
      )
    end

    it do
      is_expected.to(
        have_field(:lfo_rate).of_type(Integer).with_default_value_of(0)
      )
    end

    it do
      is_expected.to(
        have_field(:lfo_pitch_int).of_type(Integer).with_default_value_of(0)
      )
    end

    it do
      is_expected.to(
        have_field(:lfo_cutoff_int).of_type(Integer).with_default_value_of(0)
      )
    end

    it do
      is_expected.to(
        have_field(:attack).of_type(Integer).with_default_value_of(0)
      )
    end

    it do
      is_expected.to(
        have_field(:decay_release).of_type(Integer).with_default_value_of(63)
      )
    end

    it do
      is_expected.to(
        have_field(:sustain).of_type(Integer).with_default_value_of(127)
      )
    end

    it do
      is_expected.to(
        have_field(:delay_time).of_type(Integer).with_default_value_of(0)
      )
    end

    it do
      is_expected.to(
        have_field(:delay_feedback).of_type(Integer).with_default_value_of(0)
      )
    end

    it do
      is_expected.to(
        have_field(:lfo_shape).of_type(String).with_default_value_of('triangle')
      )
    end

    it do
      is_expected.to(
        have_field(:lfo_trigger_sync)
          .of_type(Mongoid::Boolean)
          .with_default_value_of(false)
      )
    end

    it do
      is_expected.to(
        have_field(:step_trigger)
          .of_type(Mongoid::Boolean)
          .with_default_value_of(false)
      )
    end

    it do
      is_expected.to(
        have_field(:tempo_delay)
          .of_type(Mongoid::Boolean)
          .with_default_value_of(true)
      )
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:slug) }

    it do
      is_expected.to validate_inclusion_of(:voice).to_allow(10, 30, 50, 70, 100, 120)
    end

    it do
      is_expected.to(
        validate_inclusion_of(:octave).to_allow(10, 30, 50, 70, 100, 120)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:detune)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:portamento)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:vco_eg_int)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:cutoff)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:peak)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:vcf_eg_int)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:lfo_rate)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:lfo_pitch_int)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:lfo_cutoff_int)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:attack)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:decay_release)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:sustain)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:delay_time)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:delay_feedback)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_inclusion_of(:lfo_shape).to_allow('saw', 'triangle', 'square')
      )
    end
  end
end
