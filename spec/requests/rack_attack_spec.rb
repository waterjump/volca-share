# spec/requests/rack_attack_spec.rb
require 'rails_helper'

# NOTE: Skipped because it requires caching in the test env which is disabled by
#   default.  It's better to keep the test and enable the special conditions if
#   it needs to be checked
RSpec.xdescribe 'Rack Attack throttling', type: :request do
  let(:ip) { '1.2.3.4' }
  let(:dummy_email) { FFaker::Internet.email }
  let(:dummy_message) { FFaker::Lorem.paragraph }
  let(:valid_attributes) do
    {
      contact: {
        subject: 'Hey',
        email: dummy_email,
        message: dummy_message
      }
    }
  end

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

  context 'when rate limiting contact submissions' do
    it 'allows requests under the limit' do
      2.times do
        post '/contacts', params: valid_attributes
        expect(response).to have_http_status(:found)
      end
    end

    it 'throttles requests over the limit' do
     2.times do
        post '/contacts', params: valid_attributes
      end
      post '/contacts', params: valid_attributes
      expect(response).to have_http_status(:too_many_requests)
    end
  end
end

