class Api::V1::BoxesController < Api::V1::BaseController
  before_action :set_space, only: [:index, :create]
  before_action :set_box, only: [:show, :update, :destroy]

  def index
    require_membership!
    render json: BoxBlueprint.render(@space.boxes)
  end

  def create
    require_membership!
    box = @space.boxes.new(box_params)
    if box.save
      render json: BoxBlueprint.render(box), status: :created
    else
      render_error(box.errors.full_messages.join(", "))
    end
  end

  def show
    authorize_box_access!
    render json: BoxBlueprint.render(@box, view: :with_items, url_helpers: url_helpers)
  end

  def scan
    @box = Box.find_by!(qr_token: params[:qr_token])
    @space = @box.space
    authorize_box_access!
    render json: BoxBlueprint.render(@box, view: :with_items, url_helpers: url_helpers)
  end

  def update
    authorize_box_access!
    if @box.update(box_params)
      render json: BoxBlueprint.render(@box)
    else
      render_error(box.errors.full_messages.join(", "))
    end
  end

  def destroy
    authorize_box_access!
    @box.destroy
    head :no_content
  end

  private

  def set_space
    @space = Space.find(params[:space_id])
  end

  def set_box
    @box = Box.find(params[:id])
    @space = @box.space
  end

  def box_params
    params.require(:box).permit(:name, :description)
  end

  def authorize_box_access!
    membership = @space.space_memberships.find_by(user: current_user)
    render json: { error: "Forbidden" }, status: :forbidden unless membership
  end
end
