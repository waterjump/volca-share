# frozen_string_literal: true

require 'rails_helper'

# TODO: need to rewrite these test to ONLY test the edit template, not the
#   form it renders
RSpec.xdescribe 'patches/edit.html.haml', type: :view do
  let!(:user) { FactoryBot.create(:user) }
  let(:user_patch) do
    VolcaShare::PatchViewModel.wrap(
      user.patches.create(FactoryBot.attributes_for(:patch))
    )
  end
  before do
    @patch = user_patch
    render template: 'patches/edit.html.haml', locals: { current_user: user }
  end
  it 'reflects patch' do
    reflects_patch(@patch, interface: rendered, form: true)
  end
end
