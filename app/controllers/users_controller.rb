class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    @patches =
      if current_user == @user
        VolcaShare::PatchViewModel.wrap(
          @user.patches.order_by(created_at: 'desc')
        )
      else
        VolcaShare::PatchViewModel.wrap(
          @user.patches.public.order_by(created_at: 'desc')
        )
      end
    @patches = Kaminari.paginate_array(@patches).page(params[:page].to_i)
  end
end
