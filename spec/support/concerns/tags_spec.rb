# frozen_string_literal: true

require 'rails_helper'

shared_examples_for 'taggable' do
  let(:model) { patch }

  before { allow(model).to receive(:tags).and_return(tags) }

  describe 'persisting' do
    context 'when tag has a leading hash mark' do
      let(:tags) { %w(#mycooltag) }

      it 'removes leading hash mark' do
        expect(model.tap(&:save).reload.tags).to eq(%w(mycooltag))
      end
    end
  end

  describe 'validating' do
    context 'when tag has a leading hash mark' do
      let(:tags) { %w(#mycooltag) }

      it 'removes leading hash mark' do
        expect(model.tap(&:validate).tags).to eq(%w(mycooltag))
      end
    end

    context 'when tag has no leading has mark' do
      let(:tags) { %w(noice) }

      it 'keeps that tag as-is' do
        expect(model.tap(&:validate).tags).to eq(tags)
      end
    end
  end
end
