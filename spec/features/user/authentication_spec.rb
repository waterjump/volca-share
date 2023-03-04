# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Authentication process', type: :feature, js: true do
  let(:user) { FactoryBot.create(:user) }

  describe 'signing up' do
    before { visit new_user_registration_path }
    it 'signs up user' do
      pw = Devise.friendly_token.first(8)
      within '#new_user' do
        fill_in 'user_email', with: FFaker::Internet.email
        fill_in 'user_username', with: FFaker::Internet.user_name
        fill_in 'user_password', with: pw
        fill_in 'user_password_confirmation', with: pw
        click_button 'Sign up'
      end

      expect(current_path).to eq(root_path)
      expect(page).to have_content('Welcome! You have signed up successfully.')
    end

    context 'when username is too shorter than two characters' do
      it 'rejects sign up' do
        pw = Devise.friendly_token.first(8)
        within '#new_user' do
          fill_in 'user_email', with: FFaker::Internet.email
          fill_in 'user_username', with: 'Q'
          fill_in 'user_password', with: pw
          fill_in 'user_password_confirmation', with: pw
          click_button 'Sign up'
        end
        expect(page).to have_content('Username is too short')
      end
    end

    context 'when email already exists' do
      it 'rejects sign up' do
        email = FFaker::Internet.email
        FactoryBot.create(:user, email: email)

        pw = Devise.friendly_token.first(8)
        within '#new_user' do
          fill_in 'user_email', with: email
          fill_in 'user_username', with: FFaker::Internet.user_name
          fill_in 'user_password', with: pw
          fill_in 'user_password_confirmation', with: pw
          click_button 'Sign up'
        end

        expect(page).to have_content('Email has already been taken')
      end
    end

    context 'when username already exists' do
      it 'rejects sign up' do
        username = 'thrillho'
        password = '12345'
        FactoryBot.create(:user, username: username)

        within '#new_user' do
          fill_in 'user_email', with: FFaker::Internet.email
          fill_in 'user_username', with: username
          fill_in 'user_password', with: password
          fill_in 'user_password_confirmation', with: password
          click_button 'Sign up'
        end

        expect(page).to have_content('Username has already been taken')
      end
    end

    context 'when username contains an invalid character' do
      it 'rejects sign up' do
        pw = Devise.friendly_token.first(8)
        within '#new_user' do
          fill_in 'user_email', with: FFaker::Internet.email
          fill_in 'user_username', with: 'Best+User'
          fill_in 'user_password', with: pw
          fill_in 'user_password_confirmation', with: pw
          click_button 'Sign up'
        end
        expect(page).to have_content('Username is invalid')
      end
    end
  end

  describe 'logging in' do
    it 'logs user in' do
      visit root_path
      click_link 'Log in'
      within '#login' do
        fill_in 'user[email]', with: user.email
        fill_in 'user[password]', with: user.password
        click_button 'Log in'
      end

      expect(current_path).to eq(root_path)
      expect(page).to have_content('Signed in successfully.')
    end

    context 'when password is incorrect' do
      it 'rejects login' do
        visit new_user_session_path
        within '#login' do
          fill_in 'user[email]', with: user.email
          fill_in 'user[password]', with: 'WrongPassword123'
          click_button 'Log in'
        end

        expect(page).to have_content('Invalid Email or password.')
        expect(current_path).to eq(new_user_session_path)
      end
    end
  end

  describe 'logging out' do
    it 'logs user out' do
      login
      click_link 'Log out'
      expect(current_path).to eq(root_path)
      expect(page).to have_content('Signed out successfully.')
    end
  end
end
