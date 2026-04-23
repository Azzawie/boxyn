class Api::V1::SpaceMembershipsController < Api::V1::BaseController
  before_action :set_space

  def create
    require_admin!
    invited = User.find_by!(email: params[:email])
    membership = SpaceMembership.new(user: invited, space: @space, role: params[:role] || :member)
    if membership.save
      render json: { message: "Invitation sent" }, status: :created
    else
      render_error(membership.errors.full_messages.join(", "))
    end
  end

  def destroy
    require_admin!
    membership = @space.space_memberships.find(params[:id])
    render_error("Cannot remove the owner", :forbidden) and return if membership.owner?
    membership.destroy
    head :no_content
  end

  private

  def set_space
    @space = Space.find(params[:space_id])
  end
end
