class Api::V1::SpacesController < Api::V1::BaseController
  before_action :set_space, only: [:show, :update, :destroy]

  def index
    spaces = current_user.spaces
    render json: SpaceBlueprint.render(spaces)
  end

  def show
    require_membership!
    return if performed?
    # Eager-load boxes and their QR code image attachments to avoid N+1
    @space = Space.includes(boxes: { qr_code_image_attachment: :blob }).find(@space.id)
    render json: SpaceBlueprint.render(@space, view: :with_boxes, url_helpers: url_helpers)
  end

  def create
    space = Space.new(space_params)
    if space.save
      SpaceMembership.create!(user: current_user, space: space, role: :owner)
      render json: SpaceBlueprint.render(space), status: :created
    else
      render_error(space.errors.full_messages.join(", "))
    end
  end

  def update
    require_admin!
    return if performed?
    if @space.update(space_params)
      render json: SpaceBlueprint.render(@space)
    else
      render_error(@space.errors.full_messages.join(", "))
    end
  end

  def destroy
    require_owner!
    return if performed?
    @space.destroy
    head :no_content
  end

  private

  def set_space
    @space = Space.find(params[:id])
  end

  def space_params
    params.require(:space).permit(:name, :description)
  end
end
