# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Contact form", type: :feature do
  context 'when user submits a contact form successfully' do
    it 'shows a message to the user' do
      visit root_path

      click_link 'Contact'

      fill_in 'subject', with: 'Test Subject'
      fill_in 'email', with: 'test@example.com'
      fill_in 'message', with: 'This is a test message.'

      click_button 'Submit'

      expect(page).to have_content('Your message has been successfully sent.')
    end
  end
end
