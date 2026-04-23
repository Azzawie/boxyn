class Api::V1::ItemsController < Api::V1::BaseController
  before_action :set_box, only: [:create]
  before_action :set_item, only: [:update, :destroy]

  def create
    authorize_space_member!(@box.space)
    item = @box.items.new(item_params)
    if item.save
      render json: ItemBlueprint.render(item, view: :with_tags), status: :created
    else
      render_error(item.errors.full_messages.join(", "))
    end
  end

  def update
    authorize_space_member!(@item.box.space)
    tag_ids = params.dig(:item, :tag_ids)
    if @item.update(item_params)
      @item.taggings.where.not(tag_id: tag_ids).destroy_all if tag_ids
      tag_ids&.each { |id| @item.taggings.find_or_create_by!(tag_id: id) }
      render json: ItemBlueprint.render(@item.reload, view: :with_tags)
    else
      render_error(@item.errors.full_messages.join(", "))
    end
  end

  def destroy
    authorize_space_member!(@item.box.space)
    @item.destroy
    head :no_content
  end

  private

  def set_box
    @box = Box.find(params[:box_id])
  end

  def set_item
    @item = Item.find(params[:id])
  end

  def item_params
    params.require(:item).permit(:name, :description, photos: [])
  end

  def authorize_space_member!(space)
    unless space.space_memberships.exists?(user: current_user)
      render json: { error: "Forbidden" }, status: :forbidden
    end
  end
end
