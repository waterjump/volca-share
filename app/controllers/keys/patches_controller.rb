# frozen_string_literal: true

module Keys
  class PatchesController < ApplicationController
    def new
      @body_class = :form
      @patch = VolcaShare::Keys::PatchViewModel.wrap(Keys::Patch.new)
      @title = 'New Keys Patch'
    end

    def create
      patch_params
      @patch_params[:slug] = @patch_params[:name].parameterize
      @patch = current_user.present? ? current_user.keys_patches.new : Keys::Patch.new
      @patch.attributes = patch_params

      respond_to do |format|
        if @patch.save
          format.html { redirect_to patch_location }
          format.json { :no_content }
        else
          format.html { render 'patches/new', local: { patch: @patch } }
          format.json { :no_content }
        end
      end
    end

    def show
      @body_class = 'show'
      patch_model =
        begin
          Patch.find_by(slug: params[:slug])
        rescue
          Patch.find(params[:id])
        end
      @patch = VolcaShare::Keys::PatchViewModel.wrap(patch_model)
      user = " by #{@patch.user.try(:username) || '¯\_(ツ)_/¯'}"
      @title = "#{@patch.name}#{user}"
    end

    private

    def patch_params
      @patch_params ||=
        params
          .require(:patch)
          .permit(
            :name,
            :voice,
            :octave,
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
            :tempo_delay,
            :notes
          )
    end

    def patch_location
      if current_user.present?
        user_keys_patch_path(current_user.slug, @patch.slug)
      else
        keys_patch_path(@patch.id)
      end
    end
  end
end
