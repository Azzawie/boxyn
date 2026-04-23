class Api::V1::BaseController < ApplicationController
  before_action :authenticate_user!
  include SpaceAuthorization

  private

  def url_helpers
    Rails.application.routes.url_helpers
  end

  def render_error(message, status = :unprocessable_entity)
    render json: { error: message }, status: status
  end
end
