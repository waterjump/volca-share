# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'errors/internal_server_error.html.haml', type: :view do
  it 'says there was an error' do
    render

    expect(rendered).to have_content(/Internal server error/)
  end
end
