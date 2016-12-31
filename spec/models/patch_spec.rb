require 'rails_helper'

RSpec.describe Patch, 'validations' do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name) }
  it { is_expected.to validate_presence_of(:slug) }
  it { is_expected.to validate_uniqueness_of(:slug) }
  it { is_expected.to validate_numericality_of(:attack) }
  it { is_expected.to validate_numericality_of(:decay_release) }
  it { is_expected.to validate_numericality_of(:cutoff_eg_int) }
  it { is_expected.to validate_numericality_of(:peak) }
  it { is_expected.to validate_numericality_of(:cutoff) }
  it { is_expected.to validate_numericality_of(:lfo_rate) }
  it { is_expected.to validate_numericality_of(:lfo_int) }
  it { is_expected.to validate_numericality_of(:vco1_pitch) }
  it { is_expected.to validate_numericality_of(:vco2_pitch) }
  it { is_expected.to validate_numericality_of(:vco3_pitch) }
  it { is_expected.to custom_validate(:audio_sample).with_validator(AudioSampleValidator) }
end
