require 'rails_helper'

RSpec.describe CreateRandomMysteryPatchJob do
  it 'updates quality value of all patches' do
    expect { described_class.new.perform }
      .to change { MysteryPatch.count }.by(1)
  end
end
