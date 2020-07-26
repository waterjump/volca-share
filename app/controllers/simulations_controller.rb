# frozen_string_literal: true

class SimulationsController < ApplicationController
  def new
    @body_class = :form
    @patch = VolcaShare::PatchViewModel.wrap(Patch.new)
    @title = 'New Patch'
  end
end
