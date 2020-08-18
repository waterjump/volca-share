require 'rails_helper'

RSpec.describe UpdatePatchAudioSampleAvailableJob do
  describe 'bass patches' do
    context 'when patch has audio sample' do
      context 'but it is not available' do
        it 'sets audio_sample_available to false' do
          patch =
            build(
              :user_patch,
              audio_sample: 'https://soundcloud.com/squidbrain/fake-track'
            )
          patch.save(validate: false)
          patch.set(audio_sample_available: true)

          expect { UpdatePatchAudioSampleAvailableJob.new.perform }.to(
            change { patch.reload.audio_sample_available }.to(false)
          )
        end
      end

      context 'and it is also available' do
        context 'and it is marked as available' do
          it 'does not change the record' do
            patch =
              create(
                :user_patch,
                audio_sample: 'https://soundcloud.com/69bot/shallow'
              )

            expect { UpdatePatchAudioSampleAvailableJob.new.perform }.not_to(
              change { patch.reload }
            )
          end
        end

        context 'and it is marked as unavailable' do
          it 'changes audio_sample_available to true' do
            patch = create(:user_patch)
            patch.set(audio_sample_available: false)

            expect { UpdatePatchAudioSampleAvailableJob.new.perform }.to(
              change { patch.reload.audio_sample_available }.to(true)
            )
          end
        end
      end
    end

    context 'when patch has no audio sample' do
      it 'does not change the record' do
        patch = create(:user_patch, audio_sample: '')

        expect { UpdatePatchAudioSampleAvailableJob.new.perform }.not_to(
          change { patch.reload }
        )
      end
    end
  end

  describe 'keys patches' do
    context 'when patch has audio sample' do
      context 'but it is not available' do
        it 'sets audio_sample_available to false' do
          patch =
            build(
              :keys_patch,
              audio_sample: 'https://soundcloud.com/squidbrain/fake-track'
            )
          patch.save(validate: false)
          patch.set(audio_sample_available: true)

          expect { UpdatePatchAudioSampleAvailableJob.new.perform }.to(
            change { patch.reload.audio_sample_available }.to(false)
          )
        end
      end

      context 'and it is also available' do
        context 'and it is marked as available' do
          it 'does not change the record' do
            patch =
              create(
                :keys_patch,
                audio_sample: 'https://soundcloud.com/69bot/shallow'
              )

            expect { UpdatePatchAudioSampleAvailableJob.new.perform }.not_to(
              change { patch.reload }
            )
          end
        end

        context 'and it is marked as unavailable' do
          it 'changes audio_sample_available to true' do
            patch = create(:keys_patch)
            patch.set(audio_sample_available: false)

            expect { UpdatePatchAudioSampleAvailableJob.new.perform }.to(
              change { patch.reload.audio_sample_available }.to(true)
            )
          end
        end
      end
    end

    context 'when patch has no audio sample' do
      it 'does not change the record' do
        patch = create(:keys_patch, audio_sample: '')

        expect { UpdatePatchAudioSampleAvailableJob.new.perform }.not_to(
          change { patch.reload }
        )
      end
    end
  end
end
