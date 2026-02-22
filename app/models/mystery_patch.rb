# frozen_string_literal: true

class MysteryPatch
  include Mongoid::Document
  include Mongoid::Timestamps

  PARAM_FIELDS = %i(
    voice detune portamento vco_eg_int cutoff peak vcf_eg_int lfo_rate
    lfo_pitch_int lfo_cutoff_int attack decay_release sustain delay_time
    delay_feedback lfo_shape lfo_trigger_sync
  ).freeze

  field :cloned_from, type: BSON::ObjectId

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

  def self.clone_from(record)
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

  def params_hash
    payload = PARAM_FIELDS.index_with do |k|
      v = self.send(k)
    end

    Digest::SHA256.hexdigest(JSON.generate(payload))
  end

  def octave
    # NotImplemented: Just return nil for PatchViewModel compatibility
    nil
  end
end
