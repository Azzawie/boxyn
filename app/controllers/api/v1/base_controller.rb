class Api::V1::BaseController < ApplicationController
  before_action :require_jwt_token!
  before_action :authenticate_user!
  include SpaceAuthorization

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  # Explicitly require an Authorization header so that session cookies
  # (added for OmniAuth support) cannot silently authenticate API requests.
  def require_jwt_token!
    return if request.headers['Authorization'].present?

    render json: { error: 'Unauthorized' }, status: :unauthorized
  end


  def render_error(message, status = :unprocessable_entity)
    render json: { error: message }, status: status
  end

  def not_found
    render json: { error: "Resource not found" }, status: :not_found
  end
end
