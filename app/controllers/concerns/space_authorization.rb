module SpaceAuthorization
  extend ActiveSupport::Concern

  def find_space
    @space = Space.find(params[:space_id] || params[:id])
  end

  def current_membership
    @current_membership ||= @space.space_memberships.find_by(user: current_user)
  end

  def require_membership!
    find_space
    render json: { error: "Forbidden" }, status: :forbidden unless current_membership
  end

  def require_admin!
    find_space
    unless current_membership&.admin? || current_membership&.owner?
      render json: { error: "Forbidden" }, status: :forbidden
    end
  end

  def require_owner!
    find_space
    render json: { error: "Forbidden" }, status: :forbidden unless current_membership&.owner?
  end
end
