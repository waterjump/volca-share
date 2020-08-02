# frozen_string_literal: true

class EmulatorsController < ApplicationController
  def new
    @body_class = :form
    @patch = VolcaShare::PatchViewModel.wrap(
      Patch.new(peak: 0, cutoff: 127)
    )
    @title = 'Volca Bass Emulator'
  end
end
