# frozen_string_literal: true

class EmulatorsController < ApplicationController
  def new
    @body_class = :form
    @patch = VolcaShare::PatchViewModel.wrap(
      Patch.new(
        attack: 0,
        decay_release: 0,
        cutoff_eg_int: 0,
        peak: 0,
        cutoff: 127,
        lfo_rate: 0,
        lfo_int: 0
      )
    )
    @title = 'Volca Bass Emulator'
  end

  def new_keys
    @body_class = :form
    @patch = VolcaShare::Keys::PatchViewModel.wrap(Keys::Patch.new(
      voice: 30,
      attack: 0,
      decay_release: 0,
      cutoff: 127,
      lfo_trigger_sync: false
    ))
    @title = 'Volca Keys Emulator'
    render 'emulators/keys/new'
  end
end
