# frozen_string_literal: true

class MysteryPatch
  class SecretPatchCloneError < StandardError; end

  include Mongoid::Document
  include Mongoid::Timestamps

  PARAM_FIELDS = %i[
    voice detune portamento vco_eg_int cutoff peak vcf_eg_int lfo_rate
    lfo_pitch_int lfo_cutoff_int attack decay_release sustain delay_time
    delay_feedback lfo_shape lfo_trigger_sync
  ].freeze

  VOICE_MIDI_VALUES = [10, 30, 50, 70, 100, 120].freeze

  field :cloned_from, type: BSON::ObjectId

  field :number, type: Integer
  field :voice, type: Integer
  field :detune, type: Integer
  field :portamento, type: Integer
  field :vco_eg_int, type: Integer
  field :cutoff, type: Integer
  field :peak, type: Integer
  field :vcf_eg_int, type: Integer
  field :lfo_rate, type: Integer
  field :lfo_pitch_int, type: Integer
  field :lfo_cutoff_int, type: Integer
  field :attack, type: Integer
  field :decay_release, type: Integer
  field :sustain, type: Integer
  field :delay_time, type: Integer
  field :delay_feedback, type: Integer
  field :lfo_shape, type: String
  field :lfo_trigger_sync, type: Boolean
  field :step_trigger, type: Boolean
  field :tempo_delay, type: Boolean

  index({ number: 1 }, unique: true)

  before_validation :assign_number, on: :create

  validates :number, presence: true, uniqueness: true

  def self.clone_from(record)
    raise(SecretPatchCloneError, 'Cannot clone a secret patch') if record.secret?

    create(
      cloned_from: record.id,
      voice: record.voice,
      detune: record.detune,
      portamento: record.portamento,
      vco_eg_int: record.vco_eg_int,
      cutoff: record.cutoff,
      peak: record.peak,
      vcf_eg_int: record.vcf_eg_int,
      lfo_rate: record.lfo_rate,
      lfo_pitch_int: record.lfo_pitch_int,
      lfo_cutoff_int: record.lfo_cutoff_int,
      attack: record.attack,
      decay_release: record.decay_release,
      sustain: record.sustain,
      delay_time: record.delay_time,
      delay_feedback: record.delay_feedback,
      lfo_shape: record.lfo_shape,
      lfo_trigger_sync: record.lfo_trigger_sync
    )
  end

  def self.generate_random(overrides: {})
    cutoff_val = overrides[:cutoff] || weighted_random_0_127
    vcf_eg_int_val = determine_vcf_eg_int_value(cutoff_val)

    new(
      voice: VOICE_MIDI_VALUES.sample,
      detune: rand(128),
      portamento: rand(128),
      vco_eg_int: random_param(preferred_weight: 5, total_weight: 6),
      cutoff: cutoff_val,
      peak: rand(128),
      vcf_eg_int: vcf_eg_int_val,
      lfo_rate: rand(128),
      lfo_pitch_int: random_param(preferred_weight: 5, total_weight: 6),
      lfo_cutoff_int: random_param(preferred_weight: 5, total_weight: 6),
      attack: random_param(preferred_weight: 2, total_weight: 3),
      decay_release: rand(128),
      sustain: rand(128),
      delay_time: rand(128),
      delay_feedback: random_param(preferred_weight: 5, total_weight: 6),
      lfo_shape: %w[saw triangle square].sample,
      lfo_trigger_sync: [true, false].sample
    )
  end

  def params_hash
    payload = PARAM_FIELDS.index_with do |k|
      send(k)
    end

    Digest::SHA256.hexdigest(JSON.generate(payload))
  end

  def octave
    # NotImplemented: Just return nil for PatchViewModel compatibility
    nil
  end

  def self.random_param(preferred_weight:, total_weight:, rng: Random)
    if rng.rand(total_weight) < preferred_weight
      0
    else
      rng.rand(128)
    end
  end

  def self.weighted_random_0_127
    pool = (0..127).flat_map { |n| (30..90).cover?(n) ? [n, n, n] : [n] }
    pool.sample
  end

  def self.determine_vcf_eg_int_value(cutoff)
    if cutoff < 30
      # Avoid completely closed filter
      rand(64..127)
    elsif cutoff > 90
      # Avoid VCF EG with inaudible effect
      rand(0..63)
    else
      rand(0..127)
    end
  end

  private

  def assign_number
    self.number ||= Counter.next!('mystery_patches.number')
  end
end
