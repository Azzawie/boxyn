class Api::V1::TagsController < Api::V1::BaseController
  before_action :set_space

  def index
    require_membership!
    render json: TagBlueprint.render(@space.tags)
  end

  def create
    require_membership!
    tag = @space.tags.new(tag_params)
    if tag.save
      render json: TagBlueprint.render(tag), status: :created
    else
      render_error(tag.errors.full_messages.join(", "))
    end
  end

  private

  def set_space
    @space = Space.find(params[:space_id])
  end

  def tag_params
    params.require(:tag).permit(:name)
  end
end
