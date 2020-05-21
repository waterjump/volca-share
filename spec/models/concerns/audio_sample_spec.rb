# frozen_string_literal: true

require 'rails_helper'

class DummyModel
  include AudioSample
  def audio_sample; end
end

RSpec.describe AudioSample do
  let(:model) { DummyModel.new }

  describe '#audio_sample_code' do
    before do
      allow(model).to(
        receive(:audio_sample).and_return(audio_sample)
      )
    end

    context 'when audio sample is from soundcloud' do
      let(:audio_sample) do
        'https://soundcloud.com/69bot/shallow'
      end

      it 'returns soundcloud embed code' do
        expect(model.audio_sample_code).to(
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
          expect(model.audio_sample_code).to be_nil
        end
      end
    end

    context 'when audio sample is regular youtube link' do
      let(:audio_sample) { 'https://youtube.com/watch?v=GF60Iuh643I' }

      it 'returns the embeddable code' do
        expect(::OEmbed::Providers::Youtube).not_to receive(:get)
        expect(model.audio_sample_code).to(
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
        expect(model.audio_sample_code).to(
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
        expect(model.audio_sample_code).to(
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
        expect(model.audio_sample_code).to be_nil
      end
    end

    context 'when freesound id is short' do
      let(:audio_sample) { 'https://freesound.org/people/Bram/sounds/11' }

      it 'parses the id' do
        expect(model.audio_sample_code)
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
        expect(model.audio_sample_code)
          .to eq(
            "<iframe frameborder='0' scrolling='no'"\
            " src='http://www.freesound.org/embed/sound/iframe/371855/simple/small/'"\
            " width='375' height='30'></iframe>"
          )
      end
    end
  end
end
