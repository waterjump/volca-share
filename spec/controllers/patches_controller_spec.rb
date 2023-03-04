# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PatchesController, type: :controller do
  login_user

  let(:valid_attributes) { attributes_for(:patch) }
  let(:invalid_attributes) { attributes_for(:patch, attack: 'bort') }
  let(:tags_string) { 'aaa,bbb,ccc' }
  let(:valid_session) { {} }
  let(:session_user) { User.first }
  let!(:patch) { create(:patch) }

  describe 'GET #index' do
    it 'assigns all patches as @patches' do
      get :index
      expect(assigns(:patches)).to eq([patch])
    end
  end

  describe 'GET #show' do
    it 'assigns the requested patch as @patch' do
      get :show, params: { id: patch.to_param }, session: valid_session
      expect(assigns(:patch)).to eq(patch)
    end
  end

  describe 'GET #new' do
    it 'assigns a new patch as @patch' do
      get :new, params: {}, session: valid_session
      expect(assigns(:patch)).to be_a_new(VolcaShare::PatchViewModel)
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested patch as @patch' do
      get :edit, params: { id: patch.to_param }, session: valid_session
      expect(assigns(:patch)).to eq(patch)
    end
  end

  describe 'GET #oembed' do
    it 'returns patch info and embed code as JSON' do
      patch = create(:user_patch)

      get :oembed,
          params: { user_slug: patch.user.slug, slug: patch.slug, format: :json },
          session: valid_session

      json = JSON.parse(response.body)
      expect(response.status).to eq(200)
      expect(json).to include(
        {
          'audio_sample_code' =>
            '<iframe width="100%" height="200" scrolling="no"'\
            ' frameborder="no" src="https://w.soundcloud.com/player/'\
            '?visual=true&url=https%3A%2F%2Fapi.soundcloud.com%2Ftracks'\
            '%2F258722704&show_artwork=true&maxheight=200"></iframe>',
          'name' => patch.name,
          'patch_location' => user_patch_path(patch.user.slug, patch.slug)
        }
      )
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new Patch' do
        expect do
          post(
            :create,
            params: { patch: valid_attributes.merge(tags: tags_string) },
            session: valid_session
          )
        end.to change(Patch, :count).by(1)
      end

      it 'assigns a newly created patch as @patch' do
        post(
          :create,
          params: { patch: valid_attributes.merge(tags: tags_string) },
          session: valid_session
        )
        expect(assigns(:patch)).to be_a(Patch)
        expect(assigns(:patch)).to be_persisted
      end

      it 'redirects to the created patch' do
        post(
          :create,
          params: { patch: valid_attributes.merge(tags: tags_string) },
          session: valid_session
        )
        expect(response).to redirect_to(
          user_patch_url(User.first.slug, Patch.last.slug)
        )
      end
    end

    context 'with invalid params' do
      it 'assigns a newly created but unsaved patch as @patch' do
        post(
          :create,
          params: { patch: invalid_attributes.merge(tags: tags_string) },
          session: valid_session
        )
        expect(assigns(:patch)).to be_a_new(VolcaShare::PatchViewModel)
      end

      it "re-renders the 'new' template" do
        post(
          :create,
          params: { patch: invalid_attributes.merge(tags: tags_string) },
          session: valid_session
        )
        expect(response).to render_template('new')
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let!(:user) { create(:user, id: '123') }
      let(:patch) { create(:user_patch, user: user) }

      let(:new_attributes) do
        attributes_for(:patch, name: 'New Weird Patch', user_id: user.id)
      end

      it 'updates the requested patch' do
        put(
          :update,
          params: {
            id: patch.id,
            patch: new_attributes.merge(tags: tags_string)
          },
          session: valid_session
        )
        patch.reload
        expect(patch.name).to eq(new_attributes[:name])
      end

      it 'assigns the requested patch as @patch' do
        put(
          :update,
          params: {
            id: patch.id,
            patch: valid_attributes.merge(tags: tags_string)
          },
          session: valid_session
        )
        expect(assigns(:patch)).to eq(patch)
      end

      it 'redirects to the patch' do
        put(
          :update,
          params: {
            id: patch.id,
            patch: patch.attributes.except('_id').merge(tags: tags_string)
          },
          session: valid_session
        )
        expect(response).to redirect_to(user_patch_path(user.slug, patch.slug))
      end
    end

    context 'with invalid params' do
      it 'assigns the patch as @patch' do
        patch = create(:user_patch)
        put(
          :update,
          params: {
            id: patch.to_param,
            patch: invalid_attributes.merge(tags: tags_string)
          },
          session: valid_session
        )
        expect(assigns(:patch)).to eq(patch)
      end

      it "re-renders the 'edit' template" do
        patch = create(:user_patch)
        put(
          :update,
          params: {
            id: patch.to_param,
            patch: invalid_attributes.merge(tags: tags_string)
          },
          session: valid_session
        )
        expect(response).to render_template('edit')
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user is author' do
      let!(:patch) { create(:user_patch, user: session_user) }

      it 'destroys the requested patch' do
        expect do
          delete :destroy,
                 params: { id: patch.to_param },
                 session: valid_session
        end.to change(Patch, :count).by(-1)

        expect { patch.reload }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end

      it 'redirects to the patches index' do
        delete :destroy,
               params: { id: patch.to_param },
               session: valid_session
        expect(response).to redirect_to(patches_url)
      end
    end

    context 'when user is not author' do
      let(:patch) { create(:user_patch) }

      it 'is disallowed' do
        delete :destroy,
                params: { id: patch.to_param },
                session: valid_session
        expect(response).to redirect_to(patch_url(patch))
      end
    end
  end
end
