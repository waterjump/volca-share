# frozen_string_literal: true

require 'rails_helper'

module VolcaShare
  module Keys
    describe PatchViewModel do

      subject { PatchViewModel.wrap(FactoryBot.build(:keys_patch)) }

      describe '#lfo_shape_saw' do
        context 'when lfo_shape is saw' do
          subject do
            PatchViewModel.wrap(FactoryBot.build(:keys_patch, lfo_shape: 'saw'))
          end

          it 'returns true' do
            expect(subject.lfo_shape_saw).to be true
          end
        end

        context 'when lfo_shape is not saw' do
          subject do
            PatchViewModel.wrap(FactoryBot.build(:keys_patch, lfo_shape: 'square'))
          end

          it 'returns false' do
            expect(subject.lfo_shape_saw).to be false
          end
        end
      end

      describe '#lfo_shape_triangle' do
        context 'when lfo_shape is triangle' do
          subject do
            PatchViewModel.wrap(FactoryBot.build(:keys_patch, lfo_shape: 'triangle'))
          end

          it 'returns true' do
            expect(subject.lfo_shape_triangle).to be true
          end
        end

        context 'when lfo_shape is not triangle' do
          subject do
            PatchViewModel.wrap(FactoryBot.build(:keys_patch, lfo_shape: 'square'))
          end

          it 'returns false' do
            expect(subject.lfo_shape_triangle).to be false
          end
        end
      end

      describe '#lfo_shape_square' do
        context 'when lfo_shape is square' do
          subject do
            PatchViewModel.wrap(FactoryBot.build(:keys_patch, lfo_shape: 'square'))
          end

          it 'returns true' do
            expect(subject.lfo_shape_square).to be true
          end
        end

        context 'when lfo_shape is not square' do
          subject do
            PatchViewModel.wrap(FactoryBot.build(:keys_patch, lfo_shape: 'saw'))
          end

          it 'returns false' do
            expect(subject.lfo_shape_square).to be false
          end
        end
      end
    end
  end
end

