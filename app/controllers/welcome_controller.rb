# frozen_string_literal: true

class WelcomeController < ApplicationController
  def index
    @title = 'Share patches for Korg Volca Bass and Korg Volca Keys'
    @body_class = :home_page

    @patches = Rails.cache.fetch('home_bass_patches', expires_in: 1.week) do
      Rails.logger.info 'FIRST CALL TO BASS PATCHES'
      VolcaShare::PatchViewModel.wrap(
        Patch.browsable.desc(:quality).desc(:created_at).limit(3)
      )
    end

    @keys_patches = Rails.cache.fetch('home_keys_patches', expires_in: 1.week) do
      VolcaShare::Keys::PatchViewModel.wrap(
        Keys::Patch.browsable.desc(:quality).desc(:created_at).limit(3)
      )
    end
  end
end
