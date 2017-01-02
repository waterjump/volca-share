require 'rails_helper'

module VolcaShare
  describe PatchViewModel do
    describe '#audio_sample_code' do
      let(:patch) do
        FactoryGirl.create(
          :patch,
          audio_sample: 'https://freesound.org/people/Bram/sounds/11/'
        )
      end

      let(:patch_2) do
        FactoryGirl.create(
          :patch,
          audio_sample: 'https://freesound.org/people/LoomyPoo/sounds/371855/'
        )
      end

      it 'parses freesound IDs from 2 to 7 digits in length' do
        view_model = PatchViewModel.new(patch)
        expect(view_model.audio_sample_code)
          .to eq(
            "<iframe frameborder='0' scrolling='no'"\
            " src='http://www.freesound.org/embed/sound/iframe/11/simple/small/'"\
            " width='375' height='30'></iframe>"
          )

        view_model = PatchViewModel.new(patch_2)
        expect(view_model.audio_sample_code)
          .to eq(
            "<iframe frameborder='0' scrolling='no'"\
            " src='http://www.freesound.org/embed/sound/iframe/371855/simple/small/'"\
            " width='375' height='30'></iframe>"
          )
      end
    end
  end
end
