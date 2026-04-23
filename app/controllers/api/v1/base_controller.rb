class Api::V1::BaseController < ApplicationController
  before_action :require_jwt_token!
  before_action :authenticate_user!
  include SpaceAuthorization

  private

  # Explicitly require an Authorization header so that session cookies
  # (added for OmniAuth support) cannot silently authenticate API requests.
  def require_jwt_token!
    return if request.headers['Authorization'].present?

    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

  def url_helpers
    Rails.application.routes.url_helpers
  end

  def render_error(message, status = :unprocessable_entity)
    render json: { error: message }, status: status
  end
end
