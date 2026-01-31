require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#format_date' do
    context 'when a valid date is given' do
      it 'formats the date correctly' do
        date = Time.zone.parse('2000-01-01')
        expect(helper.format_date(date)).to eq('January 1, 2000')
      end

      it 'formats the date correctly for a different month' do
        date = Time.zone.parse('2022-10-15')
        expect(helper.format_date(date)).to eq('October 15, 2022')
      end
    end

    context 'when nil is given' do
      it 'returns nil' do
        expect(helper.format_date(nil)).to be_nil
      end
    end
  end
end
