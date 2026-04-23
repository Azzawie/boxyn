class ItemBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :description, :created_at, :updated_at

  view :with_tags do
    association :tags, blueprint: TagBlueprint
  end

  view :with_box do
    association :tags, blueprint: TagBlueprint
    field :box_name do |item|
      item.box.name
    end
    field :box_id do |item|
      item.box.id
    end
  end

  view :full do
    association :tags, blueprint: TagBlueprint
    field :photo_urls do |item, options|
      item.photos.map { |photo| options[:url_helpers].rails_blob_url(photo) }
    end
  end
end
