# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a patch', type: :feature, js: true do
  let(:user) { FactoryBot.create(:user) }
  let(:dummy_patch) do
    FactoryBot.build(
      :patch,
      name: 'My Cool Patch',
      notes: 'This patch is cool.'
    )
  end

  context 'when user is logged in' do
    before do
      login
      visit new_patch_path
      fill_out_patch_form(dummy_patch)
      click_button 'Save'
    end

    it 'persists patch' do
      expect(Patch.first.attributes).to include(
        dummy_patch.attributes.except('_id')
      )
    end

    it 'directs user to patch show page' do
      expect(current_path).to eq(user_patch_path(user.slug, Patch.first.slug))
    end
  end

  context 'when user is anonymous' do
    let(:dummy_patch) do
      FactoryBot.build(
        :patch,
        name: 'My Cool Patch',
        notes: 'This patch is cool.',
        audio_sample: nil
      )
    end

    before do
      visit new_patch_path
      fill_out_patch_form(dummy_patch, true)
      click_button 'Save'
    end

    it 'is persisted' do
      expect(Patch.first.attributes).to include(
        dummy_patch.attributes.except('_id', 'audio_sample')
      )
    end

    it 'directs user to show patch page' do
      expect(current_path).to eq(patch_path(Patch.first))
      expect(page).to have_title("#{dummy_patch.name} by ¯\\_(ツ)_/¯ | VolcaShare")
    end

    it 'reflects the patch' do
      reflects_patch(dummy_patch)
      js_knobs_rotated(dummy_patch)
    end
  end

  describe 'audio samples' do
    describe 'adding audio sample' do
      let(:patch) { FactoryBot.create(:patch, user_id: user.id) }
      before do
        login
        visit edit_patch_path(patch.id)
      end

      it 'accepts valid soundcloud URLS' do
        fill_in 'patch[audio_sample]',
                with: 'https://soundcloud.com/69bot/take-it-to-the-streets'
        click_button 'Save'
        expect(page.body).to have_content('Patch saved successfully.')
      end

      it 'accepts valid youtube URLS' do
        fill_in 'patch[audio_sample]',
                with: 'https://youtube.com/watch?v=GF60Iuh643I'
        click_button 'Save'
        expect(page.body).to have_content('Patch saved successfully.')
      end

      it 'accepts valid freesound URLS' do
        fill_in 'patch[audio_sample]',
                with: 'https://freesound.org/people/volcashare/sounds/123456'
        click_button 'Save'
        expect(page.body).to have_content('Patch saved successfully.')
      end

      # TODO: Make sure this is covered by unit tests instead
      xit 'rejects invalid URLS' do
        fill_in 'patch[audio_sample]', with: 'https://foo.edu/69bot/shallow'
        click_button 'Save'
        expect(page).to have_content(
          'Audio sample needs to be direct SoundCloud, Freesound or YouTube link.'
        )
      end
    end

    describe 'showing audio sample' do
      context 'when audio sample is from freesound.org' do
        let!(:patch) do
          create(
            :user_patch,
            audio_sample: 'https://freesound.org/people/volcashare/sounds/123456'
          )
        end

        it 'shows iframe on patch detail page' do
          visit patch_path(patch.id)
          expect(page).to have_selector('iframe')
        end
      end
    end
  end

  it 'can be randomized' do
    default_patch = {
      attack: '63',
      cutoff: '63',
      gate_time: '127',
      lfo_target_pitch: false,
      vco3_active: 'true'
    }

    visit new_patch_path
    expect(page).to have_link('randomize')
    click_link 'randomize'
    fill_in 'patch[name]', with: 'Joey Joe Joe Junior Shabadoo'
    click_button 'Save'

    random_patch = {
      attack: page.find('#attack')['data-midi'],
      cutoff: page.find('#cutoff')['data-midi'],
      gate_time: page.find('#gate_time', visible: false)['data-midi'],
      lfo_target_pitch: page.has_css?('#lfo_target_pitch_light.lit'),
      vco3_active: page.find('#vco3_active_button')['data-active']
    }

    expect(random_patch).not_to eq(default_patch)

    visit patch_path(Patch.first)
    expect(page).not_to have_selector('#randomize')

    visit edit_patch_path(Patch.first)
    expect(page).not_to have_selector('#randomize')
  end

  context 'when MIDI is not available' do
    it 'does not randomize midi-only controls if midi not available' do
      default_patch = {
        attack: '63',
        cutoff: '63',
        lfo_target_pitch: false,
        vco3_active: 'true',
        slide_time: '63',
        expression: '127',
        gate_time: '127'
      }

      visit new_patch_path
      expect(page).to have_link('randomize')
      click_link 'randomize'
      fill_in 'patch[name]', with: 'Schnackenpfefferhausen'
      click_button 'Save'

      random_patch = {
        attack: page.find('#attack')['data-midi'],
        cutoff: page.find('#cutoff')['data-midi'],
        lfo_target_pitch: page.has_css?('#lfo_target_pitch_light.lit'),
        vco3_active: page.find('#vco3_active_button')['data-active'],
        slide_time: page.find('#slide_time', visible: false)['data-midi'],
        expression: page.find('#expression', visible: false)['data-midi'],
        gate_time: page.find('#gate_time', visible: false)['data-midi']
      }

      expect(random_patch).not_to eq(default_patch)
      expect(random_patch.slice(:slide_time, :expression, :gate_time))
        .to eq default_patch.slice(:slide_time, :expression, :gate_time)
    end
  end

  context 'when sequences are present' do
    it 'does not randomize vco groups' do
      default_patch = {
        attack: '63',
        cutoff: '63',
        gate_time: '127',
        lfo_target_pitch: false,
        vco_group_3: true,
        vco_group_2: false,
        vco_group_1: false
      }

      visit new_patch_path
      click_link 'Add sequences'
      click_link 'randomize'
      fill_in 'patch[name]', with: 'Joey Joe Joe Junior Shabadoo'
      click_button 'Save'

      random_patch = {
        attack: page.find('#attack')['data-midi'],
        cutoff: page.find('#cutoff')['data-midi'],
        gate_time: page.find('#gate_time', visible: false)['data-midi'],
        lfo_target_pitch: page.has_css?('#lfo_target_pitch_light.lit'),
        vco_group_3: page.has_css?('#vco_group_three_light.lit'),
        vco_group_2: page.has_css?('#vco_group_two_light.lit'),
        vco_group_1: page.has_css?('#vco_group_one_light.lit')
      }

      expect(random_patch).not_to eq(default_patch)
      expect(random_patch[:vco_group_3]).to eq(default_patch[:vco_group_3])
      expect(random_patch[:vco2_active]).to eq(default_patch[:vco2_active])
      expect(random_patch[:vco1_active]).to eq(default_patch[:vco1_active])
      expect(page).to have_selector('.sequence-show', count: 1)
    end
  end
end
