# frozen_string_literal: true

class WelcomeController < ApplicationController
  def index
    @title = 'Share patches for Korg Volca Bass and Korg Volca Keys'
    @body_class = :home_page
    @patches =
      VolcaShare::PatchViewModel.wrap(
        Patch.browsable.order_by(quality: :desc).limit(3)
      )
    @keys_patches =
      VolcaShare::Keys::PatchViewModel.wrap(
        Keys::Patch.browsable.order_by(quality: :desc).limit(3)
      )
  end
end
