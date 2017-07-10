require 'rails_helper'

RSpec.describe User, 'validations' do
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to validate_uniqueness_of(:email) }
  it { is_expected.to validate_presence_of(:username) }
  it { is_expected.to validate_uniqueness_of(:username) }
  it do
    is_expected.to validate_format_of(:username)
      .to_allow('hotlava69')
      .not_to_allow('qq')
      .not_to_allow('webr4%^%$E')
  end
  it { is_expected.to validate_length_of(:username).within(2..20) }
end
