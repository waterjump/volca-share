# frozen_string_literal: true

class UsersController < ApplicationController
  def show
    @user = User.find_by(slug: params[:slug])
    @patches =
      if current_user == @user
        VolcaShare::PatchViewModel.wrap(
          @user.patches.includes(:editor_picks).order_by(created_at: 'desc').to_a
        )
      else
        VolcaShare::PatchViewModel.wrap(
          @user.patches
               .browsable
               .includes(:editor_picks)
               .order_by(created_at: 'desc')
               .to_a
        )
      end

    @keys_patches =
      if current_user == @user
        VolcaShare::Keys::PatchViewModel.wrap(
          @user.keys_patches.includes(:editor_picks).order_by(created_at: 'desc').to_a
        )
      else
        VolcaShare::Keys::PatchViewModel.wrap(
          @user.keys_patches
               .browsable
               .includes(:editor_picks)
               .order_by(created_at: 'desc')
               .to_a
        )
      end
    @title = "Patches by #{@user.try(:username)}"
  end
end
