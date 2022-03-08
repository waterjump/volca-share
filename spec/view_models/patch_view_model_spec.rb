# frozen_string_literal: true

require 'rails_helper'

module VolcaShare
  describe PatchViewModel do
    subject { PatchViewModel.wrap(patch) }
    let(:patch) { build(:patch) }

    describe 'vco group methods' do
      let(:patch) { build(:patch, vco_group: vco_group) }

      describe '#vco_group_one' do
        context 'when vco_group is set to one' do
          let(:vco_group) { 'one' }

          it 'returns true' do
            expect(subject.vco_group_one).to be true
          end
        end

        context 'when vco_group is not set to one' do
          let(:vco_group) { 'two' }

          it 'returns false' do
            expect(subject.vco_group_one).to be false
          end
        end
      end

      describe '#vco_group_two' do
        context 'when vco_group is set to two' do
          let(:vco_group) { 'two' }

          it 'returns true' do
            expect(subject.vco_group_two).to be true
          end
        end

        context 'when vco_group is not set to two' do
          let(:vco_group) { 'one' }

          it 'returns false' do
            expect(subject.vco_group_two).to be false
          end
        end
      end

      describe '#vco_group_three' do
        context 'when vco_group is set to three' do
          let(:vco_group) { 'three' }

          it 'returns true' do
            expect(subject.vco_group_three).to be true
          end
        end

        context 'when vco_group is not set to three' do
          let(:vco_group) { 'two' }

          it 'returns false' do
            expect(subject.vco_group_three).to be false
          end
        end
      end
    end

    describe '#username' do
      context 'when patch has a user' do
        let(:patch) { build(:patch, user: build(:user)) }

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
        let(:patch) do
          build(:patch, gate_time: 127, expression: 127, slide_time: 63)
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

    describe '#emulator_query_string' do
      it 'returns a hash with expected values' do
        query_string = {
          attack: patch.attack,
          decay_release: patch.decay_release,
          cutoff_eg_int: patch.cutoff_eg_int,
          octave: patch.octave,
          peak: patch.peak,
          cutoff: patch.cutoff,
          lfo_rate: patch.lfo_rate,
          lfo_int: patch.lfo_int,
          vco1_pitch: patch.vco1_pitch,
          vco2_pitch: patch.vco2_pitch,
          vco3_pitch: patch.vco3_pitch,
          vco1_active: patch.vco1_active,
          vco2_active: patch.vco2_active,
          vco3_active: patch.vco3_active,
          vco_group: patch.vco_group,
          lfo_target_amp: patch.lfo_target_amp,
          lfo_target_pitch: patch.lfo_target_pitch,
          lfo_target_cutoff: patch.lfo_target_cutoff,
          lfo_wave: patch.lfo_wave ? 'square' : 'triangle',
          vco1_wave: patch.vco1_wave ? 'square' : 'sawtooth',
          vco2_wave: patch.vco2_wave ? 'square' : 'sawtooth',
          vco3_wave: patch.vco3_wave ? 'square' : 'sawtooth',
          sustain_on: patch.sustain_on,
          amp_eg_on: patch.amp_eg_on
        }

        expect(subject.emulator_query_string).to eq(query_string)
      end
    end
  end
end
