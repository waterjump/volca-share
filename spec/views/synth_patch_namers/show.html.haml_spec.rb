# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'synth_patch_namers/show.html.haml', type: :view do
  it 'displays copy' do
    render template: subject
    expect(rendered).to have_content('Need inspiration?')
  end
end
