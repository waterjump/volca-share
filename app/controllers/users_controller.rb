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
          @user.patches.browsable.order_by(created_at: 'desc')
        )
      end

    @keys_patches =
      if current_user == @user
        VolcaShare::Keys::PatchViewModel.wrap(
          @user.keys_patches.order_by(created_at: 'desc')
        )
      else
        VolcaShare::Keys::PatchViewModel.wrap(
          @user.keys_patches.browsable.order_by(created_at: 'desc')
        )
      end
    @title = "Patches by #{@user.try(:username)}"
  end
end
