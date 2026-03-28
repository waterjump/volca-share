# frozen_string_literal: true

module Keys
  class TagsController < ApplicationController
    def show
      @tag = tag_params[:tag]
      patch_models =
        Keys::Patch.where(secret: false)
                   .tagged_with(@tag)
                   .includes(:user, :editor_picks)
                   .order_by(created_at: 'desc')
                   .to_a
      @keys_patches =
        Kaminari.paginate_array(
          VolcaShare::Keys::PatchViewModel.wrap(patch_models)
        ).page(params[:page].to_i)
      @title = "##{@tag} Volca Keys Patches"
    end

    private

    def tag_params
      params.permit(:tag)
    end
  end
end
