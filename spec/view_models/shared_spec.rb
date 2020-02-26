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
      allow(view_model).to receive(:model).and_return(double(tags: %w(Larry CURLY moe)))
      expect(view_model.formatted_tags).to eq('larry, curly, moe')
      expect(view_model.formatted_tags).not_to match(/[A-Z]+/)
    end
  end

  describe '#audio_sample_code' do
    before do
      allow(view_model).to(
        receive(:model).and_return(double(audio_sample: audio_sample))
      )
    end

    context 'when audio sample is from soundcloud' do
      let(:audio_sample) do
        'https://soundcloud.com/69bot/shallow'
      end

      it 'returns soundcloud embed code' do
        expect(view_model.audio_sample_code).to(
          eq(
            '<iframe width="100%" height="81" scrolling="no" frameborder="no"' \
            ' src="https://w.soundcloud.com/player/?visual=true&url=https%3A%' \
            '2F%2Fapi.soundcloud.com%2Ftracks%2F258722704&show_artwork=true&m' \
            'axheight=81"></iframe>'
          )
        )
      end

      context 'and url is not found' do
        let(:audio_sample) { 'https://soundcloud.com/volcashare/temp' }

        it 'returns nil' do
          expect(view_model.audio_sample_code).to be_nil
        end
      end
    end

    context 'when audio sample is regular youtube link' do
      let(:audio_sample) { 'https://youtube.com/watch?v=GF60Iuh643I' }

      it 'returns the embeddable code' do
        expect(::OEmbed::Providers::Youtube).not_to receive(:get)
        expect(view_model.audio_sample_code).to(
          eq(
            '<iframe width="480" height="270" ' \
            'src="https://www.youtube.com/embed/GF60Iuh643I?feature=oembed" ' \
            'frameborder="0" allowfullscreen></iframe>'
          )
        )
      end
    end

    context 'when audio sample is shortened youtube link' do
      let(:audio_sample) { 'https://youtu.be/GF60Iuh643I' }

      it 'returns the embeddable code' do
        expect(::OEmbed::Providers::Youtube).not_to receive(:get)
        expect(view_model.audio_sample_code).to(
          eq(
            '<iframe width="480" height="270" ' \
            'src="https://www.youtube.com/embed/GF60Iuh643I?feature=oembed" ' \
            'frameborder="0" allowfullscreen></iframe>'
          )
        )
      end
    end

    context 'when youtube video is not found' do
      let(:audio_sample) { 'https://youtube.com/watch?v=QF60Iuh643I' }

      it 'returns embed code anyway (youtube will render video unavailable)' do
        expect(view_model.audio_sample_code).to(
          eq(
            '<iframe width="480" height="270" ' \
            'src="https://www.youtube.com/embed/QF60Iuh643I?feature=oembed" ' \
            'frameborder="0" allowfullscreen></iframe>'
          )
        )
      end
    end

    context 'when youtube link does not have proper id' do
      let(:audio_sample) { 'https://youtube.com/watch?v=mommy' }

      it 'returns nil' do
        expect(view_model.audio_sample_code).to be_nil
      end
    end

    context 'when freesound id is short' do
      let(:audio_sample) { 'https://freesound.org/people/Bram/sounds/11' }

      it 'parses the id' do
        expect(view_model.audio_sample_code)
          .to eq(
            "<iframe frameborder='0' scrolling='no'"\
            " src='http://www.freesound.org/embed/sound/iframe/11/simple/small/'"\
            " width='375' height='30'></iframe>"
          )
      end
    end

    context 'when freesound id is long' do
      let(:audio_sample) do
        'https://freesound.org/people/LoomyPoo/sounds/371855/'
      end

      it 'parses the id' do
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
