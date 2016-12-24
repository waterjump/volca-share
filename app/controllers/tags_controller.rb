class TagsController < ApplicationController
  # GET /tags/1
  # GET /tags/1.json
  def show
    @tag = tag_params[:tag]
    @patches =
      Kaminari.paginate_array(
        VolcaShare::PatchViewModel.wrap(
          Patch.public.tagged_with(@tag)
        )
      ).page(params[:page].to_i)
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def tag_params
    params.permit(
      :tag
    )
  end
end
