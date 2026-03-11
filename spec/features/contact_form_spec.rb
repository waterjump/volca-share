# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Contact form", type: :feature do
  context 'when user submits a contact form successfully' do
    around do |example|
      with_modified_env CONTACT_FORM_DESTINATION_EMAIL: 'owner@example.com' do
        example.run
      end
    end

    before { ActionMailer::Base.deliveries.clear }

    it 'shows a message to the user' do
      visit root_path

      click_link 'Contact'

      fill_in 'contact[name]', with: 'Stefawn'
      fill_in 'contact[email]', with: 'test@example.com'
      fill_in 'contact[subject]', with: 'Test Subject'
      fill_in 'contact[message]', with: 'This is a test message.'

      click_button 'Submit'

      expect(page).to have_content('Your message has been successfully sent.')
      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(ActionMailer::Base.deliveries.last.to).to eq(['owner@example.com'])
    end
  end
end
