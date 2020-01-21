# frozen_string_literal: true

require 'rails_helper'

module Keys
  RSpec.describe PatchesController, type: :controller do
    login_user

    let(:valid_attributes) { attributes_for(:patch) }
    let(:invalid_attributes) { attributes_for(:patch, attack: 'bort') }
    let(:tags_string) { 'aaa,bbb,ccc' }
    let(:valid_session) { {} }

    describe 'GET #new' do
      it 'assigns a new patch as @patch' do
        get :new, params: {}, session: valid_session
        expect(assigns(:patch)).to be_a_new(VolcaShare::Keys::PatchViewModel)
      end
    end
  end
end
