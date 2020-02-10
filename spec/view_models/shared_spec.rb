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
      allow(view_model).to receive(:model).and_return(double(tags: %w(Larry CURLY moe)))
      expect(view_model.formatted_tags).to eq('larry, curly, moe')
      expect(view_model.formatted_tags).not_to match(/[A-Z]+/)
    end
  end
end
