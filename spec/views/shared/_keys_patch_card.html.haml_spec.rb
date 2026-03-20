# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'shared/_keys_patch_card.html.haml', type: :view do
  let(:user) { create(:user) }
  let(:patch) { create(:keys_patch, user: create(:user)) }
  let(:patch_view_model) { VolcaShare::Keys::PatchViewModel.wrap(patch) }

  let(:render_options) do
    {
      partial: 'shared/keys_patch_card',
      locals: { current_user: nil, patch: patch_view_model }
    }
  end

  before { render render_options }

  context 'when user is logged in' do
    let(:render_options) do
      {
        partial: 'shared/keys_patch_card',
        locals: { current_user: user, patch: patch_view_model }
      }
    end

    describe 'patch made by the user' do
      let(:patch) { create(:keys_patch, user: user) }

      it 'shows the edit icon' do
        expect(rendered).to have_css('.edit.glyph')
      end

      it 'shows the delete icon' do
        expect(rendered).to have_css('.delete.glyph')
      end

      context 'when patch is secret' do
        let(:patch) do
          user.keys_patches.create(attributes_for(:keys_patch, secret: true))
        end

        it 'shows lock icon' do
          expect(rendered).to have_css('.lock.glyph')
        end
      end
    end
  end

  context 'when user is not logged in' do
    it 'does not show the edit icon' do
      expect(rendered).not_to have_css('.edit.glyph')
    end

    it 'does not show the delete icon' do
      expect(rendered).not_to have_css('.delete.glyph')
    end
  end

  it 'links to the user profile page of patch author' do
    expect(rendered).to(
      have_link(patch.user.username, href: user_path(patch.user.slug))
    )
  end

  it 'links to the user patch show page by name' do
    expect(rendered).to(
      have_link(
        patch.name,
        href: user_keys_patch_path(patch.user.slug, patch.slug)
      )
    )
  end

  it 'shows the patch notes' do
    expect(rendered).to have_content(patch_view_model.notes)
  end

  it 'shows date the patch was created' do
    expect(rendered).to have_content(format_date(patch.created_at))
  end

  it 'does not render a patch emulation control by default' do
    expect(rendered).not_to have_css('.keys-emulate-toggle')
  end

  context 'when patch has no user' do
    let(:patch) { create(:keys_patch, user: nil) }

    it 'does not render the anonymous emulation control by default' do
      expect(rendered).not_to have_css('.keys-emulate-toggle')
    end
  end

  context 'when emulation control is enabled' do
    let(:render_options) do
      {
        partial: 'shared/keys_patch_card',
        locals: {
          current_user: nil,
          patch: patch_view_model,
          show_emulation_control: true
        }
      }
    end

    it 'renders a patch emulation control with the emulation URL' do
      emulation_url = emulation_user_keys_patch_path(patch.user.slug, patch.slug)
      patch_selector =
        ".patch-holder[data-patch-id='#{patch.id}']" \
        "[data-emulation-url='#{emulation_url}']" \
        "[data-emulation-active='false']"
      toggle_selector =
        ".keys-emulate-toggle[data-patch-id='#{patch.id}']" \
        "[data-emulation-url='#{emulation_url}']" \
        "[data-emulation-active='false']" \
        "[aria-pressed='false']"

      expect(rendered).to have_css(
        patch_selector
      )
      expect(rendered).to have_css(
        toggle_selector
      )
    end

    context 'when patch has no user' do
      let(:patch) { create(:keys_patch, user: nil) }

      it 'uses the anonymous emulation URL on the control' do
        toggle_selector =
          ".keys-emulate-toggle" \
          "[data-emulation-url='#{emulation_keys_patch_path(patch.id)}']"

        expect(rendered).to have_css(
          toggle_selector
        )
      end
    end
  end
end
