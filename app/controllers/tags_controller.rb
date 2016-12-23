class TagsController < ApplicationController
  # GET /tags/1
  # GET /tags/1.json
  def show
    @tag = tag_params[:tag]
    @patches =
      VolcaShare::PatchViewModel.wrap(
        Patch.where(secret: false).tagged_with(@tag).order_by(created_at: 'desc')
      )
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def tag_params
    params.permit(
      :tag
    )
  end
end
