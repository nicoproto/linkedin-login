class RegistrationsController < Devise::RegistrationsController
  def update
    @user = User.find(current_user.id)
    email_changed = @user.email != params[:user][:email]
    is_linkedin_account = !@user.provider.blank?

    successfully_updated = if !is_linkedin_account
      @user.update_with_password(account_update_params)
    else
      @user.update_without_password(sign_up_params)
    end

    if successfully_updated
      # Sign in the user bypassing validation in case his password changed
      sign_in @user, :bypass => true
      redirect_to root_path
    else
      render "edit"
    end
  end
end
