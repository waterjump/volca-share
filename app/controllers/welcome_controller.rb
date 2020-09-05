# frozen_string_literal: true

class WelcomeController < ApplicationController
  def index
    @title = 'Share patches for Korg Volca Bass and Korg Volca Keys'
    @body_class = :home_page
    @patches =
      VolcaShare::PatchViewModel.wrap(
        Patch.browsable.desc(:quality).desc(:created_at).limit(3)
      )
    @keys_patches =
      VolcaShare::Keys::PatchViewModel.wrap(
        Keys::Patch.browsable.desc(:quality).desc(:created_at).limit(3)
      )
  end
end
