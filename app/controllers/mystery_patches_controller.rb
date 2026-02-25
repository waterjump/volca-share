# frozen_string_literal: true

class MysteryPatchesController < ApplicationController
  def mystery_patch
    respond_to do |format|
      # NOTE: This renders the page the game is played on
      format.html do
        @body_class = :form
        @body_id = :'mystery-patch'
        @body_data_attributes = { :'midi-in' => true }
        @patch = VolcaShare::Keys::PatchViewModel.wrap(Keys::Patch.new(
          voice: 30,
          attack: 0,
          decay_release: 0,
          cutoff: 127,
          lfo_trigger_sync: false
        ))
        @title = 'Mystery Patch'
        render 'emulators/keys/new', location: mystery_patch_url
      end

      # NOTE: This sends back the mystery patch params so the game can start
      format.json do
        mystery_patch = MysteryPatch.last
        render json: VolcaShare::Keys::PatchViewModel.wrap(
          mystery_patch
        ).mystery_patch_params
      end
    end
  end

  def submit_mystery_patch
    respond_to do |format|
      format.json do
        mystery_patch = MysteryPatch.find(params[:id]);

        if mystery_patch.params_hash != params[:digest]
          render(json: { message: 'Whoopsy' }, status: :bad_request) and return
        end

        results =
          MysteryPatchScorer.new(
            VolcaShare::Keys::PatchViewModel.wrap(mystery_patch).emulator_query_string,
            solution_params.to_h
          ).score

        render json: {
          message: 'Score submitted',
          results: results
        }
      end
    end
  end

  private

  def solution_params
    @solution_params ||= begin
      id = params.require(:id)
      digest = params.require(:digest)

      guess_params = params
        .require(:patch)
        .permit(
          :voice,
          :detune,
          :portamento,
          :vco_eg_int,
          :cutoff,
          :peak,
          :vcf_eg_int,
          :lfo_rate,
          :lfo_pitch_int,
          :lfo_cutoff_int,
          :attack,
          :decay_release,
          :sustain,
          :delay_time,
          :delay_feedback,
          :lfo_shape,
          :lfo_trigger_sync,
          :step_trigger,
        )

       guess_params.merge(digest: digest, id: id)
     end
  end
end
