class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    @patches =
      if current_user == @user
        VolcaShare::PatchViewModel.wrap(@user.patches)
      else
        VolcaShare::PatchViewModel.wrap(@user.patches.public)
      end
  end
end
