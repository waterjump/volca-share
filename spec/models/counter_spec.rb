# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Counter, type: :model do
  describe '.next!' do
    it 'returns 1 for a new key' do
      expect(described_class.next!('your_models.number')).to eq(1)
    end

    it 'increments the value for an existing key' do
      described_class.next!('your_models.number')

      expect(described_class.next!('your_models.number')).to eq(2)
      expect(described_class.next!('your_models.number')).to eq(3)
    end

    it 'tracks separate sequences per key' do
      expect(described_class.next!('your_models.number')).to eq(1)
      expect(described_class.next!('other_models.number')).to eq(1)
      expect(described_class.next!('your_models.number')).to eq(2)
      expect(described_class.next!('other_models.number')).to eq(2)
    end

    it 'persists the counter document' do
      described_class.next!('your_models.number')

      counter = described_class.where(key: 'your_models.number').first

      expect(counter).to be_present
      expect(counter.value).to eq(1)
    end
  end
end
