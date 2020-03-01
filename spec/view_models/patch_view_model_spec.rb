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
