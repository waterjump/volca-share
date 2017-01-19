class PatchesController < ApplicationController
  before_action :set_patch, only: [:show, :edit, :update, :destroy, :oembed]
  before_action :format_tags, only: [:create, :update]
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
    @patch_params[:slug] = @patch_params[:name].parameterize
    @patch =
      if user.present?
        user.patches.new
      else
        Patch.new
      end

    @patch.attributes = all_attributes

    respond_to do |format|
      if @patch.user.present? && @patch.save
        format.html do
          redirect_to(
            patch_location,
            notice: 'Patch saved successfully.'
          )
        end
        format.json { render :show, status: :created, location: @patch }
      elsif verify_recaptcha(model: @patch) && @patch.save
        format.html do
          redirect_to(
            patch_location,
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
      @patch_params[:slug] = @patch_params[:name].parameterize
      if @patch.update_attributes(all_attributes) # && update_sequences
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
        format.json do
          render json: {
            audio_sample_code: @patch.audio_sample_code,
            name: @patch.name,
            patch_location: patch_location
          }
        end
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
    @patch_params ||= params.require(:patch).permit!.merge!(sequence_params)
  end

  def all_attributes
    @all_attributes ||= params[:patch].except(:sequences_attributes).merge!(sequence_params)
  end

  def sequence_params
    return {} unless params[:patch].slice(:sequences_attributes).present?
    return @sequence_params if @sequence_params.present?

    final_return = {}
    final_return[:sequences_attributes] =
      cycle_sequences(params[:patch][:sequences_attributes])

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
    good_keys = [:id, :index, :note, :step_mode, :slide, :active_step, :_destroy]
    sequence = {}
    sequence[:id] = seq[:id] if seq[:id].present?
    sequence[:_destroy] = seq[:destroy] if seq[:destroy].present?
    sequence[:steps_attributes] = seq.except(:id, :destroy).each do |step|
      step.reject do |k, _v|
        !good_keys.include?(k)
      end
    end.values
    sequence
  end
end
