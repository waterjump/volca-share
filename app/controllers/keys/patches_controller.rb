# frozen_string_literal: true

module Keys
  class PatchesController < ApplicationController
    before_action :format_tags, only: [:create, :update]
    before_action :set_patch, only: [:show, :edit, :update, :destroy, :oembed]
    before_action :authenticate_user!, only: [:edit, :update, :destroy]

    def index
      @sort = :quality
      @sort = :created_at if params['sort'] == 'newest'
      @keys_patches =
        Kaminari.paginate_array(
          VolcaShare::Keys::PatchViewModel.wrap(
            Keys::Patch.browsable.includes(:user).desc(@sort).desc(:created_at)
          )
        ).page(params[:page].to_i)
      @title = 'Volca Keys Patches'
    end

    def new
      @body_class = :form
      @body_data_attributes = { :'midi-out' => true }
      @patch = VolcaShare::Keys::PatchViewModel.wrap(Keys::Patch.new)
      @title = 'New Keys Patch'
    end

    def create
      @patch_params[:slug] = @patch_params[:name].parameterize
      @patch = current_user.present? ? current_user.keys_patches.new : Keys::Patch.new
      @patch.attributes = patch_params

      respond_to do |format|
        if patch_created?
          format.html do
            redirect_to(
              patch_location,
              notice: 'Patch saved successfully.'
            )
          end

          format.json { :no_content }
        else
          @patch = VolcaShare::Keys::PatchViewModel.wrap(@patch)
          @body_class = :form
          @title = 'New Keys Patch'

          format.html do
            render 'keys/patches/new', location: new_keys_patch_url(@patch)
          end

          format.json { :no_content }
        end
      end
    end

    def show
      @body_class = 'show'
      @body_data_attributes = { :'midi-out' => true }
      if params[:user_slug].blank? && params[:slug].blank? && @patch.user.present?
        redirect_to(
          user_keys_patch_path(@patch.user.slug, @patch.slug), status: 301
        )
      end
    end

    def edit
      @body_class = :form
      @body_data_attributes = { :'midi-out' => true }
      if @patch.user_id != current_user.id
        flash[:notice] = 'You may not edit that patch.'
        redirect_to user_keys_patch_path(@patch.user.slug, @patch.slug)
      end
    end

    def update
      if @patch.user == current_user
        original_slug = @patch.slug
        @patch_params[:slug] = @patch_params[:name].parameterize

        if @patch.update_attributes(@patch_params)
          redirect_to(
            user_keys_patch_url(@patch.user.slug, @patch.slug),
            notice: 'Patch saved successfully.'
          )
        else
          @body_class = :form
          render :edit, status: :unprocessable_entity
        end
      else
        flash[:notice] = 'You are not allowed to update that patch'
        render :show, status: :unauthorized
      end
    end

    def destroy
      if current_user.present? && current_user == @patch.user && @patch.destroy
        redirect_to(
          user_url(current_user.slug),
          notice: 'Patch was successfully deleted.'
        )
      else
        notice_message = 'Patch could not be deleted.'

        if @patch.user.present?
          redirect_to(
            user_keys_patch_url(@patch.user.slug, @patch.slug),
            notice: notice_message
          )
        else
          redirect_to(
            keys_patch_url(@patch.id),
            notice: notice_message
          )
        end
      end
    end

    def oembed
      respond_to do |format|
        return unless @patch.present? && @patch.audio_sample.present?
        format.json do
          render json: {
            audio_sample_code: @patch.audio_sample_code,
            name: @patch.name,
            patch_location: user_keys_patch_path(@patch.user.slug, @patch.slug)
          }
        end
      end
    end

    private

    def set_patch
      patch_model =
        if params[:user_slug].present? && params[:slug].present?
          User
            .find_by(slug: params[:user_slug])
            .keys_patches
            .find_by(slug: params[:slug])
        else
          Patch.find(params[:id])
        end
      @patch = VolcaShare::Keys::PatchViewModel.wrap(patch_model)
      user = " by #{@patch.user.try(:username) || '¯\_(ツ)_/¯'}"
      @title = "#{@patch.name}#{user}"
    end

    def patch_created?
      (
        @patch.user.present? ||
        (!Rails.env.production? || verify_recaptcha(model: @patch))
      ) &&
        @patch.save
    end

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
            :tags,
            :notes,
            :secret,
            :audio_sample
          )
    end

    # TODO: This is used in both patch controllers. Maybe pull into module?
    def format_tags
      tags = patch_params[:tags]
      return @patch_params.merge!(tags: []) unless tags.present?
      @patch_params.merge!(tags: tags.split(',').map(&:downcase).map(&:strip))
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
