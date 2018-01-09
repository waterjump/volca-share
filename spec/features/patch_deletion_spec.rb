require 'rails_helper'

RSpec.describe 'Deleting a patch', type: :feature do
  let(:user) { FactoryBot.create(:user) }

  context 'when user is patch author' do
    it 'is possible' do
      patch1 = FactoryBot.create(:patch, secret: false, user_id: user.id)

      login
      visit patch_path(patch1)
      click_button('Delete')
      user.reload

      expect(user.patches.count).to eq(0)
    end
  end

  context 'when user is not patch author' do
    it 'is not possible' do
      patch1 = FactoryBot.create(:patch, secret: false, user_id: user.id)
      user_2 = FactoryBot.create(:user)

      login(user_2)

      visit patch_path(patch1)
      expect(page).not_to have_button('Delete')
    end
  end

  context 'when user is anonymous' do
    it 'is not possible' do
      patch1 = FactoryBot.create(:patch, secret: false, user_id: user.id)

      visit patch_path(patch1)
      expect(page).not_to have_button('Delete')
    end
  end
end
