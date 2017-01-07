class PatchesController < ApplicationController
  before_action :set_patch, only: [:show, :edit, :update, :destroy, :oembed]
  before_action :authenticate_user!, except: [
    :index,
    :show,
    :new,
    :create,
    :oembed
  ]

  # GET /patches
  # GET /patches.json
  def index
    @patches =
      Kaminari.paginate_array(
        VolcaShare::PatchViewModel.wrap(
          Patch
            .browsable
            .order_by(created_at: 'desc')
        )
      ).page(params[:page].to_i)
    @title = 'Browse Patches'
  end

  # GET /patches/1
  # GET /patches/1.json
  def show
    @body_class = :show
  end

  # GET /patches/new
  def new
    @body_class = :form
    @patch = VolcaShare::PatchViewModel.wrap(Patch.new)
    @title = 'New Patch'
  end

  # GET /patches/1/edit
  def edit
    @body_class = :form
    if @patch.user_id != current_user.id
      flash[:notice] = 'You may not edit that patch.'
      render :show
    end
  end

  # POST /patches
  # POST /patches.json
  def create
    user = current_user
    format_tags
    @patch_params[:slug] = @patch_params[:name].parameterize
    @patch =
      if user.present?
        user.patches.build(@patch_params.except(:sequences))
      else
        Patch.new(@patch_params.except(:sequences))
      end
    if @patch_params[:sequences].present?
      sequence = @patch.sequences.build
      @patch_params[:sequences].each do |step|
        sequence.steps.build(step)
      end
    end
    Rails.logger.info "69BOT - @patch_params: #{@patch_params}"
    # if @patch_params[:sequences].present?
    #   @patch.sequences.build(steps: @patch_params[:sequences].first.values)
    # end
    respond_to do |format|
      if @patch.user.present? && @patch.save
        format.html do
          redirect_to(
            user_patch_url(@patch.user.slug, @patch.slug),
            notice: 'Patch saved successfully.'
          )
        end
        format.json { render :show, status: :created, location: @patch }
      elsif verify_recaptcha(model: @patch) && @patch.save
        format.html do
          redirect_to(
            patch_url(@patch.id),
            notice: 'Patch saved successfully.'
          )
        end
        format.json { render :show, status: :created, location: @patch }
      else
        @patch = VolcaShare::PatchViewModel.wrap(@patch)
        @body_class = :form
        @title = 'New Patch'
        format.html { render :new, location: @patch }
        format.json { render json: @patch.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /patches/1
  # PATCH/PUT /patches/1.json
  def update
    respond_to do |format|
      format_tags
      @patch_params[:slug] = @patch_params[:name].parameterize
      if @patch.update(@patch_params)
        format.html do
          redirect_to(
            user_patch_url(@patch.user.slug, @patch.slug),
            notice: 'Patch saved successfully.'
          )
        end
        format.json { render :show, status: :created, location: @patch }
      else
        @body_class = :form
        format.html { render :edit }
        format.json { render json: @patch.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /patches/1
  # DELETE /patches/1.json
  def destroy
    respond_to do |format|
      if current_user == @patch.user && @patch.destroy
        format.html { redirect_to patches_url, notice: 'Patch was successfully destroyed.' }
        format.json { head :no_content }
      else
        format.html { redirect_to patch_url(@patch), notice: 'You cannot delete that patch.' }
        format.json { head :no_content }
      end
    end
  end

  def oembed
    respond_to do |format|
      if @patch.present? && @patch.audio_sample.present?
        format.json { render json: {
          audio_sample_code: @patch.audio_sample_code,
          name: @patch.name,
          patch_location: patch_location
        } }
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_patch
    patch_model =
      begin
        Patch.find_by(slug: params[:slug])
      rescue
        Patch.find(params[:slug]) # HACK: this is actually the id (-_-,)
      end
    @patch = VolcaShare::PatchViewModel.wrap(patch_model)
    user = " by #{@patch.user.try(:username)}" || ''
    @title = "#{@patch.name}#{user}"
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

  # Never trust parameters from the scary internet, only allow the white list through.
  def patch_params
    @patch_params ||= params[:patch].permit!.merge!(sequences: sequence_params)
    # (
    #   :name,
    #   :attack,
    #   :decay_release,
    #   :cutoff_eg_int,
    #   :octave,
    #   :peak,
    #   :cutoff,
    #   :lfo_rate,
    #   :lfo_int,
    #   :vco1_pitch,
    #   :vco1_active,
    #   :vco2_pitch,
    #   :vco2_active,
    #   :vco3_pitch,
    #   :vco3_active,
    #   :vco_group,
    #   :lfo_target_amp,
    #   :lfo_target_pitch,
    #   :lfo_target_cutoff,
    #   :lfo_wave,
    #   :vco1_wave,
    #   :vco2_wave,
    #   :vco3_wave,
    #   :sustain_on,
    #   :amp_eg_on,
    #   :secret,
    #   :notes,
    #   :tags,
    #   :slide_time,
    #   :expression,
    #   :gate_time,
    #   :audio_sample,
    #   :slug
    # )

  end

  def sequence_params
    steps = params[:patch][:sequences].first.map { |k,v| v }
    good_keys = [:index, :note, :step_mode, :slide, :active_step]
    steps.each do |h|
      h.reject do |k,v|
        !good_keys.include?(k)
      end
    end
  end
end
