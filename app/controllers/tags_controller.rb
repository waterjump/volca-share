# frozen_string_literal: true

class TagsController < ApplicationController
  # GET /tags/1
  def show
    @tag = tag_params[:tag]
    patch_models =
      Patch.where(secret: false)
           .tagged_with(@tag)
           .includes(:user, :editor_picks)
           .order_by(created_at: 'desc')
           .to_a
    @patches =
      Kaminari.paginate_array(
        VolcaShare::PatchViewModel.wrap(patch_models)
      ).page(params[:page].to_i)
    @title = "##{@tag} tag"
  end

  # Never trust parameters from the scary internet, only allow the white
  #   list through.
  def tag_params
    params.permit(
      :tag
    )
  end
end
