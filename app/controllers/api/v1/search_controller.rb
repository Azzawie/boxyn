class Api::V1::SearchController < Api::V1::BaseController
  def index
    space = Space.find_by(id: params[:space_id])
    unless space&.space_memberships&.exists?(user: current_user)
      return render json: { error: "Forbidden" }, status: :forbidden
    end

    if params[:q].blank?
      return render json: []
    end

    items = Item.joins(:box)
                .where(boxes: { space_id: space.id })
                .search(params[:q])
                .includes(:tags)

    render json: ItemBlueprint.render(items, view: :with_box)
  end
end
