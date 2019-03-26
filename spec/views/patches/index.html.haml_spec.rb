# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'patches/index.html.haml', type: :view do
  context 'when there are no patches' do
    it 'displays a message' do
      @patches = []
      render
      expect(rendered).to have_content('No patches to show.')
    end
  end
end
