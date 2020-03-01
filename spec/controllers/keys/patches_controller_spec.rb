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

    describe 'GET #show' do
      it 'assigns the requested patch as @patch' do
        patch = Patch.create!(valid_attributes)
        get :show, params: { id: patch.to_param }, session: valid_session
        expect(assigns(:patch)).to eq(patch)
      end
    end

    describe 'GET #edit' do
      context 'when user is logged in' do
        login_user

        context 'when patch belongs to current user' do
          let(:patch_to_edit) { @user.keys_patches.create!(valid_attributes) }

          before do
            get :edit,
                params: { slug: patch_to_edit.slug, user_slug: @user.slug },
                session: valid_session
          end

          it 'assigns the requested patch as @patch' do
            expect(assigns(:patch)).to(
              eq(VolcaShare::Keys::PatchViewModel.wrap(patch_to_edit))
            )
          end

          it 'renders edit page' do
            expect(response).to render_template('keys/patches/edit')
          end
        end

        context 'when patch does not belong to current user' do
          let(:some_other_user) { create(:user) }
          let(:patch_to_edit) do
            some_other_user.keys_patches.create!(valid_attributes)
          end

          before do
            get :edit,
                params: {
                  slug: patch_to_edit.slug,
                  user_slug: some_other_user.slug
                },
                session: valid_session
          end

          it 'redirects to show patch page' do
            expect(response).to(
              redirect_to(
                user_keys_patch_path(some_other_user.slug, patch_to_edit.slug))
            )
          end
        end
      end

      context 'when user is not logged in' do
        let(:user) { create(:user) }
        let(:patch_to_edit) { user.keys_patches.create!(valid_attributes) }

        before do
          get :edit,
              params: { slug: patch_to_edit.slug, user_slug: user.slug },
              session: valid_session
        end

        it 'shows message to user' do
          expect(flash[:alert]).to(
            eq('You need to sign in or sign up before continuing.')
          )
        end

        it 'redirects to sign in / sign_up page' do
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    describe 'PUT #update' do
      context 'when user is logged in' do
        login_user

        context 'when patch belongs to current user' do
          let(:patch_to_update) do
            @user.keys_patches.create(attributes_for(:keys_patch))
          end

          let(:new_attributes) do
            attributes_for(
              :keys_patch,
              name: 'Updated Patch'
            )
          end

          context 'when patch is valid' do
            it 'updates the patch' do
              expect do
                put :update,
                    params: { id: patch_to_update.id, patch: new_attributes },
                    session: valid_session
              end.to change { patch_to_update.reload.attributes }
            end

            it 'assigns the patch as @patch' do
              put :update,
                  params: { id: patch_to_update.id, patch: new_attributes },
                  session: valid_session

              expect(assigns(:patch).model).to eq(patch_to_update)
            end

            it 'redirects to the patch show page' do
              put :update,
                  params: { id: patch_to_update.id, patch: new_attributes },
                  session: valid_session

              expect(response).to(
                redirect_to(
                  user_keys_patch_path(@user.slug, patch_to_update.reload.slug)
                )
              )
            end
          end

          context 'when patch is not valid' do
            let(:invalid_attributes) do
              attributes_for(
                :keys_patch,
                name: 'Updated Patch',
                attack: 'bort'
              )
            end

            it 'does not update the patch' do
              expect do
                put :update,
                    params: {
                      id: patch_to_update.id,
                      patch: invalid_attributes
                    },
                    session: valid_session
              end.not_to change { patch_to_update.reload.attributes }
            end

            it 'assigns the patch as @patch' do
              put :update,
                  params: {
                    id: patch_to_update.id,
                    patch: invalid_attributes
                  },
                  session: valid_session

              expect(assigns[:patch].model).to eq(patch_to_update)
            end

            it 're-renders the edit template' do
              put :update,
                  params: {
                    id: patch_to_update.id,
                    patch: invalid_attributes
                  },
                  session: valid_session

              expect(response).to render_template('keys/patches/edit')
            end
          end
        end

        context 'when patch does not belong to current user' do
            let(:some_other_user) { create(:user) }
            let(:new_attributes) do
              attributes_for(:keys_patch, name: 'Updated Patch')
            end

            let(:patch) do
              some_other_user.keys_patches.create!(attributes_for(:keys_patch))
            end

            it 'does not update the patch' do
              expect do
                put :update,
                    params: { id: patch.id, patch: new_attributes },
                    session: valid_session
              end.not_to change { patch.reload }
            end

            it 'shows a message to the user' do
              put :update,
                  params: { id: patch.id, patch: new_attributes },
                  session: valid_session

              expect(flash[:notice]).to(
                eq('You are not allowed to update that patch')
              )
            end

            it 'assigns the patch as @patch' do
              put :update,
                  params: { id: patch.id, patch: new_attributes },
                  session: valid_session

              expect(assigns(:patch).model).to eq(patch)
            end

            it 'redirects to the patch show page' do
              put :update,
                  params: { id: patch.id, patch: new_attributes },
                  session: valid_session

              expect(response).to render_template('keys/patches/show')
            end
        end
      end

      context 'when user is not logged in' do
        let(:user) { create(:user) }
        let(:patch_to_update) { user.keys_patches.create!(valid_attributes) }
        let(:new_attributes) do
          attributes_for(:keys_patch, name: 'Updated Patch')
        end

        before do
          put :update,
              params: { id: patch_to_update.id, patch: new_attributes },
              session: valid_session
        end

        it 'shows message to user' do
          expect(flash[:alert]).to(
            eq('You need to sign in or sign up before continuing.')
          )
        end

        it 'redirects to sign in / sign_up page' do
          expect(response).to redirect_to(new_user_session_path)
        end
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
          expect(response).to render_template('keys/patches/new')
        end
      end
    end

    describe 'DELETE #destroy' do
      context 'when user is logged in' do
        login_user

        context 'when user is author' do
          it 'destroys the requested patch' do
            patch = @user.keys_patches.create(attributes_for(:keys_patch))

            expect do
              delete :destroy, params: { id: patch.id }, session: valid_session
            end.to change { Keys::Patch.count }.by(-1)
            expect(Keys::Patch.where(id: patch.id).count).to eq(0)
          end

          it 'redirects to user show page' do
            patch = @user.keys_patches.create(attributes_for(:keys_patch))

            delete :destroy, params: { id: patch.id }, session: valid_session

            expect(response).to redirect_to(user_url(@user.slug))
          end
        end

        context 'when user is not author' do
          it 'does not destroy the requested patch' do
            patch = create(:user).keys_patches.create(attributes_for(:keys_patch))

            expect do
              delete :destroy, params: { id: patch.id }, session: valid_session
            end.not_to change { Keys::Patch.count }
            expect(Keys::Patch.where(id: patch.id).count).to eq(1)
          end

          it 'redirects to patch show page' do
            patch = create(:user).keys_patches.create(attributes_for(:keys_patch))

            delete :destroy, params: { id: patch.id }, session: valid_session

            expect(response).to(
              redirect_to(user_keys_patch_url(patch.user.slug, patch.slug))
            )
          end
        end
      end

      context 'when user is not logged in' do
        it 'does not destroy the requested patch' do
          user = create(:user)
          patch = user.keys_patches.create(attributes_for(:keys_patch))
          expect do
            delete :destroy, params: { id: patch.id }, session: valid_session
          end.not_to change { Keys::Patch.count }
        end
      end
    end

    describe 'GET #oembed' do
      it 'returns patch info and embed code as JSON' do
        user = create(:user)
        patch = user.keys_patches.create(attributes_for(:keys_patch))

        get :oembed,
            params: { slug: patch.slug, format: :json },
            session: valid_session

        json = JSON.parse(response.body)
        expect(response.status).to eq(200)
        expect(json).to include(
          {
            'audio_sample_code' =>
              '<iframe width="100%" height="81" scrolling="no"'\
              ' frameborder="no" src="https://w.soundcloud.com/player/'\
              '?visual=true&url=https%3A%2F%2Fapi.soundcloud.com%2Ftracks'\
              '%2F258722704&show_artwork=true&maxheight=81"></iframe>',
            'name' => patch.name,
            'patch_location' => user_keys_patch_path(user.slug, patch.slug)
          }
        )
      end
    end
  end
end
