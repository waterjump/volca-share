require 'rails_helper'

RSpec.describe UpdatePatchQualityJob do
  it 'updates quality value of all patches' do
    old_patch = nil
    Timecop.freeze(3.years.ago) do
      old_patch = FactoryBot.create(:patch)
      expect(old_patch.quality).to be > 1
    end

    expect { UpdatePatchQualityJob.new.perform }
      .to change { old_patch.reload.quality }
  end
end
