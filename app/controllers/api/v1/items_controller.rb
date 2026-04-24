class Api::V1::ItemsController < Api::V1::BaseController
  before_action :set_box, only: [:index, :create]
  before_action :set_item, only: [:show, :update, :destroy]

  def index
    @space = @box.space
    require_membership!
    return if performed?

    items = @box.items.includes(:tags, photos_attachments: :blob)
    render json: ItemBlueprint.render(items, view: :full)
  end

  def show
    @space = @item.box.space
    require_membership!
    return if performed?
    render json: ItemBlueprint.render(@item, view: :full)
  end

  def create
    @space = @box.space
    require_membership!
    return if performed?

    item = @box.items.new(item_params)

    if item.save
      attach_photos(item)
      return unless attach_tags(item, params.dig(:item, :tag_ids))
      render json: ItemBlueprint.render(item.reload, view: :with_tags), status: :created
    else
      render_error(item.errors.full_messages.join(", "))
    end
  end

  def update
    @space = @item.box.space
    require_membership!
    return if performed?

    if @item.update(item_params)
      attach_photos(@item)
      return unless attach_tags(@item, params.dig(:item, :tag_ids))
      render json: ItemBlueprint.render(@item.reload, view: :with_tags)
    else
      render_error(@item.errors.full_messages.join(", "))
    end
  end

  def destroy
    @space = @item.box.space
    require_membership!
    return if performed?
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
    params.require(:item).permit(:name, :description)
  end

  # Attach uploaded photos if any were sent in the request.
  def attach_photos(item)
    photos = params.dig(:item, :photos)
    return if photos.blank?

    Array(photos).each { |photo| item.photos.attach(photo) }
  end

  # Sync tags for the item. Validates every tag belongs to the item's space.
  #
  # Returns true on success (or when tag_ids is omitted).
  # Returns false and renders a 422 if any tag_id is invalid — callers should
  # check the return value and halt with `return unless attach_tags(...)`.
  #
  # Semantics:
  #   nil tag_ids  → no-op (leave existing tags unchanged)
  #   []           → clear all tags
  #   [1, 2, 3]    → replace tags with exactly this set
  def attach_tags(item, tag_ids)
    return true if tag_ids.nil?

    tag_ids = Array(tag_ids).map(&:to_i).uniq

    if tag_ids.any?
      space_id = item.box.space_id
      valid_tag_ids = Tag.where(id: tag_ids, space_id: space_id).pluck(:id)

      if valid_tag_ids.size != tag_ids.size
        invalid = tag_ids - valid_tag_ids
        render_error("Tag(s) #{invalid.join(', ')} do not belong to this space", :unprocessable_entity)
        return false
      end

      item.taggings.where.not(tag_id: valid_tag_ids).delete_all
      existing = item.taggings.pluck(:tag_id)
      to_add = valid_tag_ids - existing
      Tagging.insert_all(to_add.map { |tid| { item_id: item.id, tag_id: tid } }) if to_add.any?
    else
      item.taggings.delete_all
    end

    true
  end
end
