# frozen_string_literal: true

require 'rails_helper'

class DummyViewModel < ApplicationViewModel
  include VolcaShare::Shared
  def model; end
end

RSpec.describe VolcaShare::Shared do
  let(:view_model) { DummyViewModel.new }

  describe '#checked?' do
    context 'when model field is true' do
      it 'returns hash with { checked: true }' do
        allow(view_model).to receive(:model).and_return(double(my_field: true))
        expect(view_model.checked?('my_field')).to eq(checked: true)
      end
    end

    context 'when model field is false' do
      it 'returns empty hash' do
        allow(view_model).to receive(:model).and_return(double(my_field: false))
        expect(view_model.checked?('my_field')).to eq({})
      end
    end
  end

  describe '#description' do
    before do
      allow(view_model).to receive(:model).and_return(double(notes: notes))
    end

    context 'when patch has no notes' do
      let(:notes) { nil }

      it 'returns nil' do
        expect(view_model.description).to be_nil
      end
    end

    context 'when patch notes are less than 100 characters squished' do
      let(:notes) { '  This is    a really cool patch.   ' }

      it 'returns squished notes' do
        expect(view_model.description).to eq('This is a really cool patch.')
      end
    end

    context 'when patch notes exceed 100 chatacters squished' do
      let(:notes) do
        '  This is    a really cool patch and I am going to keep' \
        ' writing more things here so that this descriptions will' \
        ' exceed one hundred characters for testing purposes'
      end

      it 'returns first 100 characters of squished notes' do
        expect(view_model.description.length).to be <= 100
      end

      it 'does not cut works in half' do
        expect(view_model.description).not_to include('descript...')
      end

      it 'adds an ellipsis' do
        expect(view_model.description[-3..-1]).to eq('...')
      end
    end
  end

  describe '#lit?' do
    context 'when model field is true' do
      it 'returns "lit"' do
        allow(view_model).to receive(:model).and_return(double(my_field: true))
        expect(view_model.lit?('my_field')).to eq('lit')
      end
    end

    context 'when model field is false' do
      it 'returns "unlit"' do
        allow(view_model).to receive(:model).and_return(double(my_field: false))
        expect(view_model.lit?('my_field')).to eq('unlit')
      end
    end
  end

  describe '#formatted_tags' do
    it 'returns a string of tags in lowercase' do
      allow(view_model).to(
        receive(:model).and_return(double(tags: %w(Larry CURLY moe)))
      )

      expect(view_model.formatted_tags).to eq('larry, curly, moe')
      expect(view_model.formatted_tags).not_to match(/[A-Z]+/)
    end
  end

  describe '#index_classes' do
    context 'when patch has no audio sample' do
      it 'returns an empty array' do
        allow(view_model).to(
          receive(:model).and_return(double(audio_sample: ''))
        )

        expect(view_model.index_classes).to eq([])
      end
    end

    context 'when patch has an audio sample' do
      it 'returns array with "has-audio" string' do
        allow(view_model).to(
          receive(:model).and_return(double(audio_sample: 'foo'))
        )

        expect(view_model.index_classes).to include('has-audio')
      end
    end
  end
end
