# frozen_string_literal: true

# TODO: Needs controller spec
class SynthPatchNamersController < ApplicationController
  def show
    @title = 'Synth Patch Namer'
  end

  def name
    respond_to do |format|
      format.json do
        render json: { name: PatchNamer.new.call }
      end
    end
  end
end
