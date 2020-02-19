# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'users/show.html.haml', type: :view do
  let(:user) { create(:user) }
  let(:bass_patches) do
    Kaminari.paginate_array(
      VolcaShare::PatchViewModel.wrap(create_list(:patch, 5, user: user))
    ).page(1)
  end

  let(:keys_patches) do
    Kaminari.paginate_array(
      VolcaShare::Keys::PatchViewModel.wrap(
        create_list(:keys_patch, 5, user: user)
      )
    ).page(1)
  end

  it 'shows the name of the user' do
    @user = user
    @patches = bass_patches
    @keys_patches = Kaminari.paginate_array([]).page(1)

    render

    expect(rendered).to have_content("Patches by #{@user.username}")
  end

  context 'when user has no keys patches' do
    before do
      @user = user
      @patches = bass_patches
      @keys_patches = Kaminari.paginate_array([]).page(1)

      render
    end

    it 'does not show "Volca Bass Patches" subheader' do
      expect(rendered).not_to have_content('Volca Bass Patches')
    end

    it 'does not show "Volca Keys Patches" subheader' do
      expect(rendered).not_to have_content('Volca Keys Patches')
    end
  end

  context 'when user has keys patches' do
    before do
      @user = user
      @patches = bass_patches
      @keys_patches = keys_patches

      render
    end

    it 'shows "Volca Bass Patches" subheader' do
      expect(rendered).to have_content('Volca Bass Patches')
    end

    it 'shows "Volca Keys Patches" subheader' do
      expect(rendered).to have_content('Volca Keys Patches')
    end
  end
end
