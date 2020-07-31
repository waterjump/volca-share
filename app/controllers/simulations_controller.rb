# frozen_string_literal: true

class SimulationsController < ApplicationController
  def new
    @body_class = :form
    @patch = VolcaShare::PatchViewModel.wrap(
      Patch.new(peak: 0, cutoff: 127)
    )
    @title = 'New Patch'
  end
end
