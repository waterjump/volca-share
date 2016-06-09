require 'rails_helper'

RSpec.describe 'Patches', type: :request do
  describe 'GET /patches' do
    it 'works! (now write some real specs)' do
      get patches_path
      expect(response).to have_http_status(200)
    end
  end
end
