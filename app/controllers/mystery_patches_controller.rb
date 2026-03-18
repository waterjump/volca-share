# frozen_string_literal: true

class MysteryPatchesController < ApplicationController
  MAX_HINTS_PER_GAME = 2

  def mystery_patch
    respond_to do |format|
      # NOTE: This renders the page the game is played on
      format.html do
        @body_class = :form
        @body_id = :'mystery-patch'
        @body_data_attributes = {
          :'midi-in' => true,
          :'test-env' => Rails.env.test?.to_s
        }
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

  def hint
    mystery_patch = MysteryPatch.find(hint_request_params[:mysteryPatchId])

    if hints_used_for(mystery_patch.id.to_s) >= MAX_HINTS_PER_GAME
      render(
        json: { message: 'Hint limit reached' },
        status: :too_many_requests
      ) and return
    end

    hint_params = MysteryPatchHintFinder.new(
      mystery_patch: mystery_patch,
      guess: guess_params.to_h.symbolize_keys
    ).hint_params

    increment_hints_used_for(mystery_patch.id.to_s)

    render json: {
      hint_params: hint_params,
      hints_used: hints_used_for(mystery_patch.id.to_s),
      hints_remaining: MAX_HINTS_PER_GAME - hints_used_for(mystery_patch.id.to_s)
    }
  end

  private

  def hint_request_params
    @hint_request_params ||= params.permit(:mysteryPatchId)
  end

  def guess_params
    @guess_params ||= params
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
  end

  def solution_params
    @solution_params ||= begin
      id = params.require(:id)
      digest = params.require(:digest)

      guess_params.merge(digest: digest, id: id)
    end
  end

  def hints_used_for(mystery_patch_id)
    mystery_patch_hint_counts[mystery_patch_id].to_i
  end

  def increment_hints_used_for(mystery_patch_id)
    mystery_patch_hint_counts[mystery_patch_id] = hints_used_for(mystery_patch_id) + 1
  end

  def mystery_patch_hint_counts
    session[:mystery_patch_hint_counts] ||= {}
  end
end
