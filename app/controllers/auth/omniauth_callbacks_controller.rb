class Auth::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    handle_auth
  end

  def apple
    handle_auth
  end

  private

  def handle_auth
    @user = User.from_omniauth(request.env["omniauth.auth"])
    if @user.persisted?
      sign_in @user
      render json: UserBlueprint.render(@user), status: :ok
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
