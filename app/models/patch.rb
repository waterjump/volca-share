require 'audio_sample_validator.rb'

class Patch
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Document::Taggable
  include ActiveModel::Validations

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
  field :slug, type: String
  field :quality, type: Float
  field :quality_updated_at, type: Time

  belongs_to :user,
             class_name: 'User',
             inverse_of: :patches,
             optional: true
  embeds_many :sequences, class_name: 'Sequence'
  accepts_nested_attributes_for :sequences, allow_destroy: true

  validates_presence_of :name, :slug
  validates_uniqueness_of :name, :slug
  validates :attack, numericality: { greater_than: -1, less_than: 128 }
  validates :decay_release, numericality: { greater_than: -1, less_than: 128 }
  validates :cutoff_eg_int, numericality: { greater_than: -1, less_than: 128 }
  validates :peak, numericality: { greater_than: -1, less_than: 128 }
  validates :cutoff, numericality: { greater_than: -1, less_than: 128 }
  validates :lfo_rate, numericality: { greater_than: -1, less_than: 128 }
  validates :lfo_int, numericality: { greater_than: -1, less_than: 128 }
  validates :vco1_pitch, numericality: { greater_than: -1, less_than: 128 }
  validates :vco2_pitch, numericality: { greater_than: -1, less_than: 128 }
  validates :vco3_pitch, numericality: { greater_than: -1, less_than: 128 }
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

  # NOTE: Fine for now but needs to be a cron eventually.
  def persist_quality
    set(quality: calculate_quality)
    Patch.all.each do |patch|
      patch.set(quality: patch.calculate_quality)
    end
  end

  protected

  def calculate_quality
    qual = 1
    qual += 1 if sequences.any?
    qual += 1 if audio_sample.present?
    qual += 1 if tags.any?
    qual += 0.5 if notes.present?
    qual += 2 if notes.length > 30

    base_score = Math.log([qual, 1].max)

    time_difference = (Time.now - created_at) / 2.month.to_f

    if time_difference > 1
      x = time_difference - 1
      base_score = base_score * Math.exp(-8*x*x)
    end

    base_score
  end
end
