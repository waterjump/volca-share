require 'rails_helper'

RSpec.feature 'tags', type: :feature, js: true do
  let(:patches) do
    [
      FactoryGirl.create(:patch, name: 'Patch 1', tags: %w(lead cool)),
      FactoryGirl.create(:patch, name: 'Patch 2', tags: %w(bass wow)),
      FactoryGirl.create(:patch, name: 'Patch 3', tags: %w(lead scary))
    ]
  end

  let(:user) { FactoryGirl.create(:user) }

  before(:each) do
    user.patches << patches
    visit root_path
  end

  def perform_around
    VCR.use_cassette('oembed') do
      yield
    end
  end

  around(:each) do |example|
    perform_around(&example)
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

  scenario 'have audio previews' do
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
    expect(page).to have_selector('.speaker')
    page.find('.speaker', match: :first).trigger('click')

    expect(page).to have_selector('#preview-modal-body')
  end

  scenario 'patch detail page shows tags as links' do
    click_link 'Patch 1'
    expect(page).to have_link('#lead')

    click_link('#lead')
    expect(page).to have_title('#lead tag | VolcaShare')
    expect(page).to have_content('#lead')
    expect(page).to have_link('Patch 1')
    expect(page).to have_link('Patch 3')
    expect(page).not_to have_link('Patch 2')
  end

  scenario 'patch index page shows tags as links' do
    expect(page).to have_link('#lead')

    first(:link, '#lead').click
    expect(page).to have_content('#lead')
    expect(page).to have_link('Patch 1')
    expect(page).to have_link('Patch 3')
    expect(page).not_to have_link('Patch 2')
  end

  scenario 'visit a tag page that doesn\'t exist' do
    visit('/tags/show?tag=fake')
    expect(page).to have_content('No patches to show.')
  end
end
