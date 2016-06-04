require 'rails_helper'

RSpec.feature "the home page", :type => :feature do
  before(:each) { visit root_path }

  scenario "user can access homepage" do
    expect(page.status_code).to eq(200)
  end

  scenario "user see relevant information" do
    expect(page).to have_content(/Volca Share/i)
  end
end
