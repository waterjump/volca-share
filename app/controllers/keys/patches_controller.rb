# frozen_string_literal: true

module Keys
  class PatchesController < ApplicationController
    def new
      @body_class = :form
      @patch = VolcaShare::Keys::PatchViewModel.wrap(Keys::Patch.new)
      @title = 'New Keys Patch'
    end
  end
end
