# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MysteryPatchResultsFromCookie do
  subject(:results) { described_class.new(raw_cookie) }

  let(:raw_cookie) do
    {
      mysteryPatchId: mystery_patch.id.to_s,
      results: { total_score: 54.66 }
    }.to_json
  end

  let(:mystery_patch) do
    MysteryPatch.generate_random.tap(&:save).reload
  end

  describe '#total_score' do
    context 'when the cookie JSON contains total_score' do
      it 'returns the total_score' do
        expect(results.total_score).to eq(54.66)
      end
    end

    context 'when total_score is missing' do
      let(:raw_cookie) do
        {
          results: {}
        }.to_json
      end

      it 'returns nil' do
        expect(results.total_score).to be_nil
      end
    end

    context 'when results is missing' do
      let(:raw_cookie) { {}.to_json }

      it 'returns nil' do
        expect(results.total_score).to be_nil
      end
    end

    context 'when the cookie is nil' do
      let(:raw_cookie) { nil }

      it 'returns nil' do
        expect(results.total_score).to be_nil
      end
    end

    context 'when the cookie is blank' do
      let(:raw_cookie) { '' }

      it 'returns nil' do
        expect(results.total_score).to be_nil
      end
    end

    context 'when the cookie is invalid JSON' do
      let(:raw_cookie) { 'not json' }

      it 'returns nil' do
        expect(results.total_score).to be_nil
      end
    end
  end

  describe '#callout_text' do
    context 'when total_score is present' do
      it 'returns the total_score followed by a percent sign' do
        expect(results.callout_text).to eq('54.66%')
      end
    end

    context 'when total_score is missing' do
      let(:raw_cookie) do
        {
          results: {}
        }.to_json
      end

      it 'returns default text' do
        expect(results.callout_text).to eq(described_class::DEFAULT_TEXT)
      end
    end

    context 'when the cookie is nil' do
      let(:raw_cookie) { nil }

      it 'returns default text' do
        expect(results.callout_text).to eq(described_class::DEFAULT_TEXT)
      end
    end

    context 'when the cookie is invalid JSON' do
      let(:raw_cookie) { 'not json' }

      it 'returns default text' do
        expect(results.callout_text).to eq(described_class::DEFAULT_TEXT)
      end
    end
  end
end
