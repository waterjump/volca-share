require 'audio_sample_validator.rb'

class Patch
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Document::Taggable
  include ActiveModel::Validations

  field :name, type: String
  field :attack, type: Integer
  field :decay_release, type: Integer
  field :cutoff_eg_int, type: Integer
  field :octave, type: Integer
  field :peak, type: Integer
  field :cutoff, type: Integer
  field :lfo_rate, type: Integer
  field :lfo_int, type: Integer
  field :vco1_pitch, type: Integer, default: 63
  field :vco1_active, type: Mongoid::Boolean, default: true
  field :vco2_pitch, type: Integer, default: 63
  field :vco2_active, type: Mongoid::Boolean, default: true
  field :vco3_pitch, type: Integer, default: 63
  field :vco3_active, type: Mongoid::Boolean, default: true
  field :vco_group, type: String, default: 'three'
  field :lfo_target_amp, type: Mongoid::Boolean
  field :lfo_target_pitch, type: Mongoid::Boolean
  field :lfo_target_cutoff, type: Mongoid::Boolean, default: true
  field :lfo_wave, type: Boolean, default: false
  field :vco1_wave, type: Boolean, default: false
  field :vco2_wave, type: Boolean, default: false
  field :vco3_wave, type: Boolean, default: true
  field :sustain_on, type: Mongoid::Boolean
  field :amp_eg_on, type: Mongoid::Boolean
  field :slide_time, type: Integer, default: 63
  field :expression, type: Integer, default: 127
  field :gate_time, type: Integer, default: 127
  field :secret, type: Mongoid::Boolean, default: false
  field :notes, type: String
  field :audio_sample, type: String
  field :slug, type: String

  belongs_to :user, class_name: 'User', inverse_of: :patches
  embeds_many :sequences, class_name: 'Sequence'
  accepts_nested_attributes_for :sequences, allow_destroy: true

  validates_presence_of :name, :slug
  validates_uniqueness_of :name, :slug
  validates :attack, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 127 }
  validates :decay_release, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 127 }
  validates :cutoff_eg_int, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 127 }
  validates :peak, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 127 }
  validates :cutoff, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 127 }
  validates :lfo_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 127 }
  validates :lfo_int, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 127 }
  validates :vco1_pitch, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 127 }
  validates :vco2_pitch, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 127 }
  validates :vco3_pitch, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 127 }
  validates :audio_sample, audio_sample: true

  scope :browsable, -> { where(secret: false, :user_id.ne => nil) }
end
