# frozen_string_literal: true

require 'rails_helper'

module Keys
  RSpec.describe PatchesController, type: :controller do
    let(:valid_attributes) { attributes_for(:keys_patch) }
    let(:invalid_attributes) { attributes_for(:keys_patch, attack: 'bort') }
    let(:valid_session) { {} }

    describe 'GET #new' do
      it 'assigns a new patch as @patch' do
        get :new, params: {}, session: valid_session
        expect(assigns(:patch)).to be_a_new(VolcaShare::Keys::PatchViewModel)
      end
    end

    describe 'POST #create' do
      let(:params) { attributes_for(:keys_patch) }

      context 'when user is logged in' do
        login_user

        it 'creates a new patch' do
          expect do
            post :create, params: { patch: params }, session: valid_session
          end.to change { Patch.count }.by(1)
        end

        it 'redirects to user patch show page' do
          post :create, params: { patch: params }, session: valid_session
          expect(response).to redirect_to(user_keys_patch_path(User.first.slug, Patch.last.slug))
        end
      end

      context 'when user is not logged in' do
        it 'creates a new patch' do
          expect do
            post :create, params: { patch: params }, session: valid_session
          end.to change { Patch.count }.by(1)
        end

        it 'redirects to anonymous patch show page' do
          post :create, params: { patch: params }, session: valid_session
          expect(response).to redirect_to(keys_patch_path(Patch.last.id))
        end
      end

      context 'when parameters are invalid' do
        it 'does not create a patch' do
          expect do
            post(
              :create,
              params: { patch: invalid_attributes },
              session: valid_session
            )
          end.not_to change { Patch.count }
        end

        it 'redirects to edit path' do
          post(
            :create,
            params: { patch: invalid_attributes },
            session: valid_session
          )
          expect(response).to render_template('patches/new')
        end
      end
    end
  end
end
