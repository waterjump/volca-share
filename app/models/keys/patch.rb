# frozen_string_literal: true

module Keys
  class Patch
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mongoid::Document::Taggable
    include ActiveModel::Validations

    field :name, type: String
    field :secret, type: Boolean, default: false
    field :notes, type: String
    field :slug, type: String

    field :voice, type: Integer, default: 57
    field :octave, type: Integer, default: 57
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

    midi_validation_options = {
      numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 127 }
    }

    validates_presence_of :name, :slug
    validates :voice, inclusion: { in: [0, 19, 38, 57, 76, 95] }
    validates :octave, inclusion: { in: [0, 19, 38, 57, 76, 95] }
    validates :detune, :only_integer, midi_validation_options
    validates :portamento, :only_integer, midi_validation_options
    validates :vco_eg_int, :only_integer, midi_validation_options
    validates :cutoff, :only_integer, midi_validation_options
    validates :peak, :only_integer, midi_validation_options
    validates :vcf_eg_int, :only_integer, midi_validation_options
    validates :lfo_rate, :only_integer, midi_validation_options
    validates :lfo_pitch_int, :only_integer, midi_validation_options
    validates :lfo_cutoff_int, :only_integer, midi_validation_options
    validates :attack, :only_integer, midi_validation_options
    validates :decay_release, :only_integer, midi_validation_options
    validates :sustain, :only_integer, midi_validation_options
    validates :delay_time, :only_integer, midi_validation_options
    validates :delay_feedback, :only_integer, midi_validation_options
    validates :lfo_shape, inclusion: { in: %w(saw triangle square) }
  end
end

