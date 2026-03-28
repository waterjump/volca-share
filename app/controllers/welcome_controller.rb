# frozen_string_literal: true

class WelcomeController < ApplicationController
  def index
    @title = 'Share patches for Korg Volca Bass and Korg Volca Keys'
    @body_class = :home_page

    patch_models = Rails.cache.fetch('home_bass_patches', expires_in: 1.week) do
      Rails.logger.info 'FIRST CALL TO BASS PATCHES'
      Patch
        .browsable
        .includes(:editor_picks)
        .desc(:quality)
        .desc(:created_at)
        .limit(3)
        .to_a
    end
    @patches = VolcaShare::PatchViewModel.wrap(patch_models)

    keys_patch_models = Rails.cache.fetch('home_keys_patches', expires_in: 1.week) do
      Keys::Patch
        .browsable
        .includes(:editor_picks)
        .desc(:quality)
        .desc(:created_at)
        .limit(3)
        .to_a
    end
    @keys_patches = VolcaShare::Keys::PatchViewModel.wrap(keys_patch_models)
  end
end
