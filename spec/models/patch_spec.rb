require 'rails_helper'

RSpec.describe Patch, 'validations' do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name) }
  it { should validate_inclusion_of(:vco1_wave).to_allow('saw', 'square') }
  it { should validate_inclusion_of(:vco2_wave).to_allow('saw', 'square') }
  it { should validate_inclusion_of(:vco3_wave).to_allow('saw', 'square') }
  it { should validate_inclusion_of(:lfo_wave).to_allow('triangle', 'square') }
end
