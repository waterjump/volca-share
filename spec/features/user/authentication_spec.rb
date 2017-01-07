require 'rails_helper'

RSpec.feature 'Authentication process', type: :feature do
  let(:user) { FactoryGirl.create(:user) }
  before(:each) { visit root_path }

  scenario 'User can sign up' do
    visit(new_user_registration_path)
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

  scenario 'User logs in' do
    click_link 'Log in'
    login
    expect(current_path).to eq(root_path)
    expect(page).to have_content('Signed in successfully.')
  end

  scenario 'User logs out' do
    click_link 'Log in'
    login
    click_link 'Log out'
    expect(current_path).to eq(root_path)
    expect(page).to have_content('Signed out successfully.')
  end

  scenario 'User enters incorrect password' do
    click_link 'Log in'
    within '#login' do
      fill_in 'user[email]', with: user.email
      fill_in 'user[password]', with: 'WrongPassword123'
      click_button 'Log in'
    end
    expect(page).to have_content('Invalid Email or password.')
    expect(current_path).to eq(new_user_session_path)
  end

  scenario 'User enters 2 character username' do
    visit(new_user_registration_path)
    pw = Devise.friendly_token.first(8)
    within '#new_user' do
      fill_in 'user_email', with: FFaker::Internet.email
      fill_in 'user_username', with: 'qq'
      fill_in 'user_password', with: pw
      fill_in 'user_password_confirmation', with: pw
      click_button 'Sign up'
    end
    expect(page).to have_content('Username is too short')
  end

  scenario 'User enters username with invalid character' do
    visit(new_user_registration_path)
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

  scenario 'User signs up with existing email' do
    visit(new_user_registration_path)
    pw = Devise.friendly_token.first(8)
    email = FFaker::Internet.email

    within '#new_user' do
      fill_in 'user_email', with: email
      fill_in 'user_username', with: FFaker::Internet.user_name
      fill_in 'user_password', with: pw
      fill_in 'user_password_confirmation', with: pw
      click_button 'Sign up'
    end

    expect(current_path).to eq(root_path)
    expect(page).to have_content('Welcome! You have signed up successfully.')

    click_link 'Log out'
    visit(new_user_registration_path)
    pw = Devise.friendly_token.first(8)
    within '#new_user' do
      fill_in 'user_email', with: email
      fill_in 'user_username', with: FFaker::Internet.user_name
      fill_in 'user_password', with: pw
      fill_in 'user_password_confirmation', with: pw
      click_button 'Sign up'
    end

    expect(page).to have_content('Email is already taken')
  end

  scenario 'User signs up with existing username' do
    visit(new_user_registration_path)
    pw = Devise.friendly_token.first(8)
    username = 'hotlava69'
    within '#new_user' do
      fill_in 'user_email', with: FFaker::Internet.email
      fill_in 'user_username', with: username
      fill_in 'user_password', with: pw
      fill_in 'user_password_confirmation', with: pw
      click_button 'Sign up'
    end

    expect(current_path).to eq(root_path)
    expect(page).to have_content('Welcome! You have signed up successfully.')

    click_link 'Log out'
    visit(new_user_registration_path)
    within '#new_user' do
      fill_in 'user_email', with: FFaker::Internet.email
      fill_in 'user_username', with: username
      fill_in 'user_password', with: pw
      fill_in 'user_password_confirmation', with: pw
      click_button 'Sign up'
    end

    expect(page).to have_content('Username is already taken')
  end
end
