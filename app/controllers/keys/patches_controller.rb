# frozen_string_literal: true

module Keys
  class PatchesController < ApplicationController
    def new
      @body_class = :form
      @patch = VolcaShare::Keys::PatchViewModel.wrap(Keys::Patch.new)
      @title = 'New Keys Patch'
    end

    def create
      patch_params
      @patch_params[:slug] = @patch_params[:name].parameterize
      @patch = current_user.present? ? current_user.keys_patches.new : Keys::Patch.new
      @patch.attributes = patch_params

      respond_to do |format|
        if @patch.save
          format.html do
            redirect_to patch_location
          end

          format.json { :no_content }
        else
          format.html { render 'patches/new', local: { patch: @patch } }
          format.json { :no_content }
        end
      end
    end

    private

    def patch_params
      @patch_params ||=
        params
          .require(:patch)
          .permit(
            :name,
            :attack
          )
    end

    def patch_location
      if current_user.present?
        user_keys_patch_path(current_user.slug, @patch.slug)
      else
        keys_patch_path(@patch.id)
      end
    end
  end
end
