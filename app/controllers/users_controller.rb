# frozen_string_literal: true

class UsersController < ApplicationController
  def show
    @user = User.find_by(slug: params[:slug])
    @patches =
      if current_user == @user
        VolcaShare::PatchViewModel.wrap(
          @user.patches.order_by(created_at: 'desc')
        )
      else
        VolcaShare::PatchViewModel.wrap(
          @user.patches.where(secret: false).order_by(created_at: 'desc')
        )
      end
    @patches = Kaminari.paginate_array(@patches).page(params[:page].to_i)
    @title = "Patches by #{@user.try(:username)}"
  end
end
