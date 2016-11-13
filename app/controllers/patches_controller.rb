class PatchesController < ApplicationController
  before_action :set_patch, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!, except: [:index, :show]

  # GET /patches
  # GET /patches.json
  def index
    @patches = VolcaShare::PatchViewModel.wrap(Patch.public)
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
    @patch = user.patches.build(patch_params)

    respond_to do |format|
      if @patch.save
        format.html { redirect_to edit_patch_url(@patch), notice: 'Patch saved successfully.' }
        format.json { render :show, status: :created, location: @patch }
      else
        format.html { render :new }
        format.json { render json: @patch.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /patches/1
  # PATCH/PUT /patches/1.json
  def update
    respond_to do |format|
      if @patch.update(patch_params)
        format.html { redirect_to @patch, notice: 'Patch was successfully updated.' }
        format.json { render :show, status: :ok, location: @patch }
      else
        format.html { render :edit }
        format.json { render json: @patch.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /patches/1
  # DELETE /patches/1.json
  def destroy
    @patch.destroy
    respond_to do |format|
      format.html { redirect_to patches_url, notice: 'Patch was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_patch
    @patch = VolcaShare::PatchViewModel.wrap(Patch.find(params[:id]))
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def patch_params
    params[:patch].permit(
      :name,
      :attack,
      :decay_release,
      :cutoff_eg_int,
      :peak,
      :cutoff,
      :lfo_rate,
      :lfo_int,
      :vco1_pitch,
      :vco1_active,
      :vco2_pitch,
      :vco2_active,
      :vco3_pitch,
      :vco3_active,
      :vco_group,
      :lfo_target_amp,
      :lfo_target_pitch,
      :lfo_target_cutoff,
      :lfo_wave,
      :vco1_wave,
      :vco2_wave,
      :vco3_wave,
      :sustain_on,
      :amp_eg_on,
      :private?,
      :notes
    )
  end
end
