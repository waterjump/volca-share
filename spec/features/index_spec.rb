require 'rails_helper'

RSpec.feature 'patch index', type: :feature, js: true do
  def perform_around
    VCR.use_cassette('oembed') do
      yield
    end
  end

  around(:each) do |example|
    perform_around(&example)
  end

  let(:user) { FactoryGirl.create(:user) }

  before(:each) { visit root_path }

  scenario 'can be deleted by author on patch browse page' do
    FactoryGirl.create(:patch, secret: false, user_id: user.id)

    login

    visit patches_path
    expect(page).to have_button('Delete')

    click_button('Delete')
    user.reload
    expect(user.patches.count).to eq(0)

    visit patches_path
    expect(page).to have_selector 'h1', text: 'Patches', visible: false
    expect(page).to have_title('Browse Patches | VolcaShare')
    expect(page).to have_content('No patches to show.')
  end

  scenario 'cannot be deleted by non-author on patch browse page' do
    FactoryGirl.create(:patch, secret: false, user_id: user.id)
    user_2 = FactoryGirl.create(:user)

    login(user_2)

    visit patches_path
    expect(page).not_to have_button('Delete')
  end

  scenario 'that are private are not show on the index' do
    patch1 = FactoryGirl.create(:patch, secret: false, user_id: user.id)
    patch2 = FactoryGirl.create(:patch, secret: true, user_id: user.id)

    visit root_path

    expect(page).to have_content(patch1.name)
    expect(page).not_to have_content(patch2.name)
  end

  scenario 'shows anonymous patches' do
    patch1 = FactoryGirl.create(:patch, secret: false)

    visit root_path

    expect(page).to have_content(patch1.name)
  end

  scenario 'patches are paginated on index' do
    user = FactoryGirl.create(:user)
    first_patch = FactoryGirl.create(:patch, secret: false, user_id: user.id)
    30.times do
      FactoryGirl.create(:patch, secret: false, user_id: user.id)
    end
    last_patch = FactoryGirl.create(:patch, secret: false, user_id: user.id)

    visit patches_path
    expect(page).to have_content(last_patch.name)
    expect(page).not_to have_content(first_patch.name)
    expect(page).to have_selector('.pagination')
    expect(page).to have_selector('.patch-holder', count: 20)
    within '.pagination' do
      expect(page).to have_link('2')
      expect(page).not_to have_link('3')
    end

    click_link '2'
    expect(page).not_to have_content(last_patch.name)
    expect(page).to have_content(first_patch.name)
    expect(page).to have_selector('.pagination')
    expect(page).to have_selector('.patch-holder', count: 12)
    expect(page).to have_link('2')
  end

  scenario 'user patches are shown on tag pages' do
    patch1 = FactoryGirl.create(
      :patch,
      secret: false,
      user_id: user.id,
      tag_list: 'cool'
    )
    patch2 = FactoryGirl.create(:patch, secret: false, tag_list: 'cool')

    visit patch_path(patch2)

    click_link('#cool')
    expect(page).to have_selector 'h1', text: '#cool tags', visible: false
    expect(page).to have_content(patch1.name)
    expect(page).to have_content(patch2.name)

    click_link(patch2.name)
    expect(current_path).to eq(patch_path(patch2.id))
  end

  scenario 'anonymous patches are shown on tag pages' do
    patch1 = FactoryGirl.create(
      :patch,
      secret: false,
      user_id: nil,
      tag_list: 'cool'
    )

    visit('/tags/show?tag=cool')
    expect(page).to have_content(patch1.name)
  end

  scenario 'audio samples can be provided by registered users' do
    # Soundcloud comes from FactoryGirl
    patch = FactoryGirl.create(:patch, user_id: user.id, secret: false)

    visit patches_path
    within '.patch-holder' do
      # speaker icon
      expect(page).to have_xpath('/html/body/div[1]/div[2]/div[3]/div[2]/div[1]')
      find(:xpath, '/html/body/div[1]/div[2]/div[3]/div[2]/div[1]').click
    end

    expect(page).to have_selector('iframe')
    expect(page).to have_link('Go to Patch')

    click_link 'Go to Patch'
    expect(page.current_path).to eq(user_patch_path(user.slug, patch.slug))
  end
end
