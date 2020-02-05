# frozen_string_literal: true

require 'rails_helper'

module VolcaShare
  describe PatchViewModel do

    subject do
      PatchViewModel.wrap(FactoryBot.build(:patch))
    end

    describe '#vco_group_one' do
      context 'when vco_group is set to one' do
        subject do
          PatchViewModel.wrap(FactoryBot.build(:patch, vco_group: 'one'))
        end
        it 'returns true' do
          expect(subject.vco_group_one).to be true
        end
      end
      context 'when vco_group is not set to one' do
        subject do
          PatchViewModel.wrap(FactoryBot.build(:patch, vco_group: 'two'))
        end
        it 'returns false' do
          expect(subject.vco_group_one).to be false
        end
      end
    end

    describe '#vco_group_two' do
      context 'when vco_group is set to two' do
        subject do
          PatchViewModel.wrap(FactoryBot.build(:patch, vco_group: 'two'))
        end
        it 'returns true' do
          expect(subject.vco_group_two).to be true
        end
      end
      context 'when vco_group is not set to two' do
        subject do
          PatchViewModel.wrap(FactoryBot.build(:patch, vco_group: 'one'))
        end
        it 'returns false' do
          expect(subject.vco_group_two).to be false
        end
      end
    end

    describe '#vco_group_three' do
      context 'when vco_group is set to three' do
        subject do
          PatchViewModel.wrap(FactoryBot.build(:patch, vco_group: 'three'))
        end
        it 'returns true' do
          expect(subject.vco_group_three).to be true
        end
      end

      context 'when vco_group is not set to three' do
        subject do
          PatchViewModel.wrap(FactoryBot.build(:patch, vco_group: 'two'))
        end
        it 'returns false' do
          expect(subject.vco_group_three).to be false
        end
      end
    end

    describe '#index_classes' do
      context 'when patch is not secret and doesn\'t have audio' do
        subject do
          PatchViewModel.wrap(
            FactoryBot.build(:patch, audio_sample: nil)
          )
        end
        it 'returns nil' do
          expect(subject.index_classes).to be_nil
        end
      end
      context 'when the patch is secret' do
        subject do
          PatchViewModel.wrap(FactoryBot.build(:patch, secret: true))
        end
        it 'returns an array with a string \'secret\'' do
          expect(subject.index_classes).to include('secret')
        end
      end
      context 'when patch has and audio sample' do
        it 'returns and array with a string \'has-audio\'' do
          expect(subject.index_classes).to include('has-audio')
        end
      end
    end

    describe '#username' do
      context 'when patch has a user' do
        subject do
          PatchViewModel.wrap(
            FactoryBot.build(:patch, user: FactoryBot.build(:user))
          )
        end
        it 'returns username' do
          expect(subject.username).to eq(subject.user.username)
        end
      end
      context 'when patch is anonymous' do
        it 'returns nil' do
          expect(subject.username).to be_nil
        end
      end
    end

    describe '#audio_sample_code' do
      context 'when audio sample is from soundcloud' do
        context 'and url is not found' do
          subject do
            PatchViewModel.wrap(
              FactoryBot.build(
                :patch,
                audio_sample: 'https://soundcloud.com/volcashare/temp'
              )
            )
          end

          it 'returns nil' do
            expect(subject.audio_sample_code).to be_nil
          end
        end
      end

      context 'when freesound id is short' do
        subject do
          PatchViewModel.wrap(
            FactoryBot.build(
              :patch,
              audio_sample: 'https://freesound.org/people/Bram/sounds/11/'
            )
          )
        end
        it 'parses the id' do
          expect(subject.audio_sample_code)
            .to eq(
              "<iframe frameborder='0' scrolling='no'"\
              " src='http://www.freesound.org/embed/sound/iframe/11/simple/small/'"\
              " width='375' height='30'></iframe>"
            )
        end
      end
      context 'when freesound id is long' do
        subject do
          PatchViewModel.wrap(
            FactoryBot.build(
              :patch,
              audio_sample: 'https://freesound.org/people/LoomyPoo/sounds/371855/'
            )
          )
        end
        it 'parses the id' do
          expect(subject.audio_sample_code)
            .to eq(
              "<iframe frameborder='0' scrolling='no'"\
              " src='http://www.freesound.org/embed/sound/iframe/371855/simple/small/'"\
              " width='375' height='30'></iframe>"
            )
        end
      end
    end

    describe '#description' do
      context 'when patch has no notes' do
        subject do
          PatchViewModel.wrap(FactoryBot.build(:patch, notes: nil))
        end
        it 'returns nil' do
          expect(subject.description).to be_nil
        end
      end
      context 'when patch notes are less than 100 characters squished' do
        notes = '  This is    a really cool patch.   '
        subject do
          PatchViewModel.wrap(FactoryBot.build(:patch, notes: notes))
        end

        it 'returns squished notes' do
          expect(subject.description).to eq('This is a really cool patch.')
        end
      end
      context 'when patch notes exceed 100 chatacters squished' do
        notes = '  This is    a really cool patch and I am going to keep' \
                ' writing more things here so that this descriptions will' \
                ' exceed one hundred characters for testing purposes'
        subject do
          PatchViewModel.wrap(FactoryBot.build(:patch, notes: notes))
        end
        it 'returns first 100 characters of squished notes' do
          expect(subject.description.length).to be <= 100
        end
        it 'does not cut works in half' do
          expect(subject.description).not_to include('descript...')
        end
        it 'adds an ellipsis' do
          expect(subject.description[-3..-1]).to eq('...')
        end
      end
    end

    describe '#formatted_tags' do
      it 'returns a string of tags in lowercase' do
        expect(subject.formatted_tags).not_to match(/[A-Z]+/)
      end
    end

    describe '#show_midi_only_knobs?' do
      context 'when midi only patch fields are default values' do
        subject do
          PatchViewModel.wrap(
            FactoryBot.build(
              :patch,
              gate_time: 127,
              expression: 127,
              slide_time: 63
            )
          )
        end
        it 'returns false' do
          expect(subject.show_midi_only_knobs?).to be false
        end
      end
      context 'when midi only patch fields are not default values' do
        it 'returns true' do
          expect(subject.show_midi_only_knobs?).to be true
        end
      end
    end
  end
end
