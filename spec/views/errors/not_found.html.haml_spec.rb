# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'errors/not_found.html.haml', type: :view do
  it 'says the page is not found' do
    render

    expect(rendered).to have_content(/not.*found/)
  end
end
