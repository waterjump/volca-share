# frozen_string_literal: true

module Keys
  class TagsController < ApplicationController
    def show
      @tag = tag_params[:tag]
      @keys_patches =
        Kaminari.paginate_array(
          VolcaShare::Keys::PatchViewModel.wrap(
            Keys::Patch.where(secret: false)
                       .tagged_with(@tag)
                       .includes(:user)
                       .order_by(created_at: 'desc')
          )
        ).page(params[:page].to_i)
      @title = "##{@tag} Volca Keys Patches"
    end

    private

    def tag_params
      params.permit(:tag)
    end
  end
end
