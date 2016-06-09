require 'rails_helper'

RSpec.feature 'Authentication process', type: :feature do
  let(:user) { FactoryGirl.create(:user) }
  before(:each) { visit root_path }

  def fill_in_login_fields
    fill_in 'user[email]', with: user.email
    fill_in 'user[password]', with: user.password
    click_button 'Log in'
  end

  scenario 'User can sign up' do
    click_link 'Log in'
    click_link 'Sign up'
    pw = Devise.friendly_token.first(8)
    within '#new_user' do
      fill_in 'user_email', with: FFaker::Internet.email
      fill_in 'user_password', with: pw
      fill_in 'user_password_confirmation', with: pw
      click_button 'Sign up'
    end

    expect(current_path).to eq(root_path)
    expect(page).to have_content('Welcome! You have signed up successfully.')
  end

  scenario 'User logs in' do
    click_link 'Log in'
    fill_in_login_fields
    expect(current_path).to eq(root_path)
    expect(page).to have_content('Signed in successfully.')
  end

  scenario 'User logs out' do
    click_link 'Log in'
    fill_in_login_fields
    click_link 'Log out'
    expect(current_path).to eq(root_path)
    expect(page).to have_content('Signed out successfully.')
  end

  scenario 'User enters incorrect password' do
    click_link 'Log in'
    fill_in 'user[email]', with: user.email
    fill_in 'user[password]', with: 'WrongPassword123'
    click_button 'Log in'
    expect(page).to have_content('Invalid Email or password.')
    expect(current_path).to eq(new_user_session_path)
  end
end
