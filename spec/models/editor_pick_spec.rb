# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EditorPick, type: :model do
  describe 'fields' do
    it do
      is_expected.to(
        have_field(:list_key).of_type(String).with_default_value_of('default')
      )
    end
  end

  describe 'associations' do
    it 'belongs to a polymorphic pickable record' do
      relation = described_class.relations['pickable']

      expect(relation.key).to eq('pickable_id')
      expect(relation.polymorphic?).to be(true)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:list_key) }
    it { is_expected.to validate_presence_of(:pickable) }

    it 'does not allow the same record to be picked twice for the same list' do
      patch = create(:patch)
      create(:editor_pick, pickable: patch, list_key: 'default')

      duplicate_pick = build(:editor_pick, pickable: patch, list_key: 'default')

      expect(duplicate_pick).to be_invalid
      expect(duplicate_pick.errors[:pickable_id]).to include('has already been taken')
    end

    it 'allows the same patch to be used in different lists' do
      patch = create(:patch)
      create(:editor_pick, pickable: patch, list_key: 'default')

      other_pick = build(:editor_pick, pickable: patch, list_key: 'staff_favorites')

      expect(other_pick).to be_valid
    end

    it 'allows a keys patch to be selected' do
      editor_pick = build(:keys_editor_pick)

      expect(editor_pick).to be_valid
    end

    it 'does not allow records other than Patch and Keys::Patch' do
      editor_pick = build(:editor_pick, pickable: create(:user))

      expect(editor_pick).to be_invalid
      expect(editor_pick.errors[:pickable]).to include(
        'must be a Patch or Keys::Patch'
      )
    end
  end

  describe 'indexes' do
    it 'indexes picks by list and picked record uniquely' do
      expect(described_class.index_specifications.map(&:key)).to include(
        { list_key: 1, pickable_type: 1, pickable_id: 1 }
      )
    end
  end

  describe '.create_from' do
    it 'creates an editor pick for a bass patch' do
      patch = create(:patch)

      editor_pick = described_class.create_from(patch)

      expect(editor_pick).to be_persisted
      expect(editor_pick.pickable).to eq(patch)
      expect(editor_pick.list_key).to eq('default')
    end

    it 'creates an editor pick for a keys patch' do
      patch = create(:keys_patch)

      editor_pick = described_class.create_from(patch)

      expect(editor_pick).to be_persisted
      expect(editor_pick.pickable).to eq(patch)
      expect(editor_pick.list_key).to eq('default')
    end

    it 'allows overriding the list key' do
      patch = create(:patch)

      editor_pick = described_class.create_from(patch, list_key: 'homepage')

      expect(editor_pick).to be_persisted
      expect(editor_pick.list_key).to eq('homepage')
    end
  end
end
