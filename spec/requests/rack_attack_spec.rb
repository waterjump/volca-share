# frozen_string_literal: true

require 'rails_helper'

# NOTE: Skipped because it requires caching in the test env which is disabled by
#   default.  It's better to keep the test and enable the special conditions if
#   it needs to be checked
RSpec.xdescribe 'Rack Attack throttling', type: :request do
  let(:ip) { '1.2.3.4' }

  around do |example|
    # Enable caching
    caching_enabled = ActionController::Base.perform_caching
    ActionController::Base.perform_caching = true
    Rails.cache.clear

    example.run

    # Disable caching
    ActionController::Base.perform_caching = caching_enabled
    Rails.cache.clear
  end

  before do
    allow_any_instance_of(ActionDispatch::Request).to receive(:ip).and_return(ip)
  end

  context 'when blocking suspicious requests' do
    context 'when reqest path ends with ".php"' do
      it 'blocks the request after the second bad request' do
        get '/wp-login.php'
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end

