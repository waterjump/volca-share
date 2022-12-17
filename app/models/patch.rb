# frozen_string_literal: true

require 'audio_sample_validator.rb'

class Patch
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Document::Taggable
  include ActiveModel::Validations
  include AudioSample
  include Tags

  field :name, type: String
  field :attack, type: Integer, default: 63
  field :decay_release, type: Integer, default: 63
  field :cutoff_eg_int, type: Integer, default: 63
  field :octave, type: Integer, default: 63
  field :peak, type: Integer, default: 63
  field :cutoff, type: Integer, default: 63
  field :lfo_rate, type: Integer, default: 63
  field :lfo_int, type: Integer, default: 63
  field :vco1_pitch, type: Integer, default: 63
  field :vco1_active, type: Mongoid::Boolean, default: true
  field :vco2_pitch, type: Integer, default: 63
  field :vco2_active, type: Mongoid::Boolean, default: true
  field :vco3_pitch, type: Integer, default: 63
  field :vco3_active, type: Mongoid::Boolean, default: true
  field :vco_group, type: String, default: 'three'
  field :lfo_target_amp, type: Mongoid::Boolean, default: false
  field :lfo_target_pitch, type: Mongoid::Boolean, default: false
  field :lfo_target_cutoff, type: Mongoid::Boolean, default: true
  field :lfo_wave, type: Boolean, default: false
  field :vco1_wave, type: Boolean, default: false
  field :vco2_wave, type: Boolean, default: false
  field :vco3_wave, type: Boolean, default: true
  field :sustain_on, type: Mongoid::Boolean, default: false
  field :amp_eg_on, type: Mongoid::Boolean, default: false
  field :slide_time, type: Integer, default: 63
  field :expression, type: Integer, default: 127
  field :gate_time, type: Integer, default: 127
  field :secret, type: Mongoid::Boolean, default: false
  field :notes, type: String
  field :audio_sample, type: String
  field :audio_sample_available, type: Boolean
  field :slug, type: String
  field :quality, type: Float
  field :quality_updated_at, type: Time

  belongs_to :user,
             class_name: 'User',
             inverse_of: :patches,
             optional: true
  embeds_many :sequences, class_name: 'Sequence'
  accepts_nested_attributes_for :sequences, allow_destroy: true

  midi_validation_options = {
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 127 }
  }

  validates_presence_of :name, :slug
  validates_uniqueness_of :name, :slug
  validates :attack, midi_validation_options
  validates :decay_release, midi_validation_options
  validates :cutoff_eg_int, midi_validation_options
  validates :peak, midi_validation_options
  validates :cutoff, midi_validation_options
  validates :lfo_rate, midi_validation_options
  validates :lfo_int, midi_validation_options
  validates :vco1_pitch, midi_validation_options
  validates :vco2_pitch, midi_validation_options
  validates :vco3_pitch, midi_validation_options
  validates :audio_sample, audio_sample: true
  validate :patch_is_not_default

  scope :browsable, -> { where(secret: false) }

  after_save :persist_quality

  def patch_is_not_default
    not_default =
      attack_changed_from_default? ||
      decay_release_changed_from_default? ||
      cutoff_eg_int_changed_from_default? ||
      octave_changed_from_default? ||
      peak_changed_from_default? ||
      cutoff_changed_from_default? ||
      lfo_rate_changed_from_default? ||
      lfo_int_changed_from_default? ||
      vco1_pitch_changed_from_default? ||
      vco1_active_changed_from_default? ||
      vco2_pitch_changed_from_default? ||
      vco2_active_changed_from_default? ||
      vco3_pitch_changed_from_default? ||
      vco3_active_changed_from_default? ||
      vco_group_changed_from_default? ||
      lfo_target_amp_changed_from_default? ||
      lfo_target_pitch_changed_from_default? ||
      lfo_target_cutoff_changed_from_default? ||
      lfo_wave_changed_from_default? ||
      vco1_wave_changed_from_default? ||
      vco2_wave_changed_from_default? ||
      vco3_wave_changed_from_default? ||
      sustain_on_changed_from_default? ||
      amp_eg_on_changed_from_default?

    errors.add(:patch, 'is not valid.') unless not_default
  end

  def persist_quality
    set(quality: calculate_quality)
  end

  private

  def calculate_quality
    qual = 1
    qual += 3 if audio_sample_available?
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
