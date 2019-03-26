# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'patches/edit.html.haml', type: :view do
  # TODO: move this to a spec helper specific to view specs
  let!(:user) { FactoryBot.build(:user) }
  let(:user_patch) do
    VolcaShare::PatchViewModel.wrap(
      user.patches.build(FactoryBot.attributes_for(:patch))
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
