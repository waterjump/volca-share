class TagsController < ApplicationController
  # GET /tags/1
  # GET /tags/1.json
  def show
    @tag = tag_params[:tag]
    @patches =
      VolcaShare::PatchViewModel.wrap(
        Patch.public.tagged_with(@tag)
      )
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def tag_params
    params.permit(
      :tag
    )
  end
end
