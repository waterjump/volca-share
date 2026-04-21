# frozen_string_literal: true

class PatchesController < ApplicationController
  before_action :set_patch, only: [:show, :edit, :update, :destroy, :oembed, :emulation]
  before_action :format_tags, only: [:create, :update]
  before_action :authenticate_user!, except: [
    :index,
    :show,
    :new,
    :create,
    :oembed,
    :emulation
  ]

  # GET /patches
  def index
    @sort = params['sort'] == 'newest' ? :created_at : :quality
    @show_audio_filter = true
    @body_class = :index

    patch_models =
      if params[:audio_only] == 'true'
        Patch
          .browsable
          .where(audio_sample_available: true)
          .includes(:user, :editor_picks)
          .desc(@sort)
          .desc(:created_at)
      else
        Patch
          .browsable
          .includes(:user, :editor_picks)
          .desc(@sort)
          .desc(:created_at)
      end
    patch_models = patch_models.to_a

    @patches =
      Kaminari.paginate_array(
        VolcaShare::PatchViewModel.wrap(patch_models)
      ).page(params[:page].to_i)
    @title = 'Volca Bass Patches'
  end

  def show
    @body_class = :show
    @body_data_attributes = { :'midi-out' => true }
    if params[:user_slug].blank? && params[:slug].blank? && @patch.user.present?
      redirect_to user_patch_path(@patch.user.slug, @patch.slug), status: 301
    end
  end

  # GET /patches/new
  def new
    @body_class = :form
    @body_data_attributes = { :'midi-out' => true }
    @patch = VolcaShare::PatchViewModel.wrap(Patch.new)
    @title = 'New Bass Patch'
  end

  # GET /patches/1/edit
  def edit
    @body_class = :form
    @body_data_attributes = { :'midi-out' => true }
    if @patch.user_id != current_user.id
      flash[:notice] = 'You may not edit that patch.'
      render :show
    end
  end

  # POST /patches
  def create
    @patch_params[:slug] = @patch_params[:name].parameterize
    @patch = current_user.present? ? current_user.patches.new : Patch.new
    @patch.attributes = all_attributes

    if patch_created?
      redirect_to(
        patch_location,
        notice: 'Patch saved successfully.'
      )
    else
      @patch = VolcaShare::PatchViewModel.wrap(@patch)
      @body_class = :form
      @title = 'New Patch'
      render :new, location: @patch
    end
  end

  # PATCH/PUT /patches/1
  def update
    @patch_params[:slug] = @patch_params[:name].parameterize
    if @patch.update_attributes(all_attributes)
      redirect_to(
        user_patch_url(@patch.user.slug, @patch.slug),
        notice: 'Patch saved successfully.'
      )
    else
      @body_class = :form
      render :edit
    end
  end

  # DELETE /patches/1
  def destroy
    if current_user == @patch.user && @patch.destroy
      redirect_to patches_url, notice: 'Patch was successfully destroyed.'
    else
      redirect_to patch_url(@patch), notice: 'You cannot delete that patch.'
    end
  end

  def oembed
    respond_to do |format|
      return unless @patch.present? && @patch.audio_sample.present?
      format.json do
        render json: {
          audio_sample_code: @patch.audio_sample_code,
          name: @patch.name,
          patch_location: patch_location
        }
      end
    end
  end

  def emulation
    respond_to do |format|
      format.json do
        render json: {
          id: @patch.id.to_s,
          name: @patch.name,
          patch_location: patch_location,
          emulator_params: @patch.emulator_query_string
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
          .patches
          .includes(:editor_picks)
          .find_by(slug: params[:slug])
      else
        Patch.includes(:editor_picks).find(params[:id])
      end
    @patch = VolcaShare::PatchViewModel.wrap(patch_model)
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

  def format_tags
    tags = patch_params[:tags]
    return @patch_params.merge!(tags: []) unless tags.present?
    @patch_params.merge!(tags: tags.split(',').map(&:downcase).map(&:strip))
  end

  def patch_location
    if @patch.user.present?
      user_patch_path(@patch.user.slug, @patch.slug)
    else
      patch_path(@patch.id)
    end
  end

  # White list parameters
  def patch_params
    @patch_params ||= params.require(:patch).permit!.merge!(sequence_params)
  end

  def all_attributes
    @all_attributes ||=
      params[:patch].except(:sequences_attributes)
                    .merge!(sequence_params)
  end

  def sequence_params
    return {} unless params[:patch].slice(:sequences_attributes).present?
    return @sequence_params if @sequence_params.present?

    final_return = {}
    final_return[:sequences_attributes] =
      cycle_sequences(params[:patch][:sequences_attributes].to_h)

    @sequence_params ||= final_return
  end

  def cycle_sequences(hash)
    return {} unless hash.present?
    paramz = []
    hash.values.each do |seq|
      paramz << format_sequence(seq)
    end
    paramz
  end

  def format_sequence(seq)
    ok_keys = [:id, :index, :note, :step_mode, :slide, :active_step, :_destroy]
    seq = seq.to_h.with_indifferent_access
    sequence = {}
    sequence[:id] = seq[:id] if seq[:id].present?
    sequence[:_destroy] = seq[:destroy] if seq[:destroy].present?
    sequence[:steps_attributes] =
      seq.except(:id, :destroy)
         .values
         .filter_map do |step|
           next unless step.respond_to?(:to_h)

           attrs = step.to_h.with_indifferent_access.slice(*ok_keys)
           next if attrs.empty?

           attrs
         end
         .sort_by { |step| step[:index].to_i }
    sequence
  end
end
