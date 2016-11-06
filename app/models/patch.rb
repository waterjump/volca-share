class Patch
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :attack, type: Integer
  field :decay_release, type: Integer
  field :cutoff_eg_int, type: Integer
  field :peak, type: Integer
  field :cutoff, type: Integer
  field :lfo_rate, type: Integer
  field :lfo_int, type: Integer
  field :vco1_pitch, type: Integer
  field :vco1_active, type: Mongoid::Boolean, default: true
  field :vco2_pitch, type: Integer
  field :vco2_active, type: Mongoid::Boolean, default: true
  field :vco3_pitch, type: Integer
  field :vco3_active, type: Mongoid::Boolean, default: true
  field :vco_group, type: String, default: 'three'
  field :lfo_target_amp, type: Mongoid::Boolean
  field :lfo_target_pitch, type: Mongoid::Boolean
  field :lfo_target_cutoff, type: Mongoid::Boolean, default: true
  field :lfo_wave, type: String
  field :vco1_wave, type: String
  field :vco2_wave, type: String
  field :vco3_wave, type: String, default: 'square'
  field :sustain_on, type: Mongoid::Boolean
  field :amp_eg_on, type: Mongoid::Boolean
  field :private?, type: Mongoid::Boolean, default: false
  field :notes, type: String

  belongs_to :user, class_name: 'User', inverse_of: :patches

  validates_presence_of :name
  validates_uniqueness_of :name
  validates :vco1_wave, inclusion: { in: %w(saw square) }
  validates :vco2_wave, inclusion: { in: %w(saw square) }
  validates :vco3_wave, inclusion: { in: %w(saw square) }
  validates :lfo_wave, inclusion: { in: %w(triangle square) }
end
