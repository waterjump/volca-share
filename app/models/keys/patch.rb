# frozen_string_literal: true

require 'audio_sample_validator.rb'

module Keys
  class Patch
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mongoid::Document::Taggable
    include ActiveModel::Validations
    include AudioSample

    field :name, type: String
    field :secret, type: Boolean, default: false
    field :audio_sample, type: String
    field :audio_sample_available, type: Boolean
    field :notes, type: String
    field :slug, type: String
    field :quality, type: Float

    field :voice, type: Integer, default: 70
    field :octave, type: Integer, default: 70
    field :detune, type: Integer, default: 0
    field :portamento, type: Integer, default: 0
    field :vco_eg_int, type: Integer, default: 0
    field :cutoff, type: Integer, default: 63
    field :peak, type: Integer, default: 0
    field :vcf_eg_int, type: Integer, default: 0
    field :lfo_rate, type: Integer, default: 0
    field :lfo_pitch_int, type: Integer, default: 0
    field :lfo_cutoff_int, type: Integer, default: 0
    field :attack, type: Integer, default: 0
    field :decay_release, type: Integer, default: 63
    field :sustain, type: Integer, default: 127
    field :delay_time, type: Integer, default: 0
    field :delay_feedback, type: Integer, default: 0
    field :lfo_shape, type: String, default: 'triangle'
    field :lfo_trigger_sync, type: Boolean, default: false
    field :step_trigger, type: Boolean, default: false
    field :tempo_delay, type: Boolean, default: true

    belongs_to :user,
               class_name: 'User',
               inverse_of: :keys_patches,
               optional: true

    midi_validation_options = {
      numericality: {
        only_integer: true,
        greater_than_or_equal_to: 0,
        less_than_or_equal_to: 127
      }
    }

    validates_presence_of :name, :slug
    validates :voice, inclusion: { in: [10, 30, 50, 70, 100, 120] }
    validates :octave, inclusion: { in: [10, 30, 50, 70, 100, 120] }
    validates :detune, midi_validation_options
    validates :portamento, midi_validation_options
    validates :vco_eg_int, midi_validation_options
    validates :cutoff, midi_validation_options
    validates :peak, midi_validation_options
    validates :vcf_eg_int, midi_validation_options
    validates :lfo_rate, midi_validation_options
    validates :lfo_pitch_int, midi_validation_options
    validates :lfo_cutoff_int, midi_validation_options
    validates :attack, midi_validation_options
    validates :decay_release, midi_validation_options
    validates :sustain, midi_validation_options
    validates :delay_time, midi_validation_options
    validates :delay_feedback, midi_validation_options
    validates :lfo_shape, inclusion: { in: %w(saw triangle square) }
    validates :audio_sample, audio_sample: true
    validate :patch_is_not_default

    scope :browsable, -> { where(secret: false) }

    after_save :persist_quality

    def persist_quality
      set(quality: calculate_quality)
    end

    private

    def patch_is_not_default
      not_default =
        voice_changed_from_default? ||
        octave_changed_from_default? ||
        detune_changed_from_default? ||
        portamento_changed_from_default? ||
        vco_eg_int_changed_from_default? ||
        cutoff_changed_from_default? ||
        peak_changed_from_default? ||
        vcf_eg_int_changed_from_default? ||
        lfo_rate_changed_from_default? ||
        lfo_pitch_int_changed_from_default? ||
        lfo_cutoff_int_changed_from_default? ||
        attack_changed_from_default? ||
        decay_release_changed_from_default? ||
        sustain_changed_from_default? ||
        delay_time_changed_from_default? ||
        delay_feedback_changed_from_default? ||
        lfo_shape_changed_from_default? ||
        lfo_trigger_sync_changed_from_default? ||
        step_trigger_changed_from_default? ||
        tempo_delay_changed_from_default?

      errors.add(:patch, 'is not valid.') unless not_default
    end

    def calculate_quality
      qual = 1
      qual += 3 if audio_sample.present?
      qual += 1 if tags.any?
      qual += 0.5 if notes.present?
      qual += 2 if notes.length > 30

      base_score = Math.log([qual, 1].max)

      time_difference = (Time.now - created_at) / 2.years.to_f

      if time_difference > 1
        x = time_difference - 1
        base_score = base_score * Math.exp(-8*x*x)
      end

      base_score
    end
  end
end
