class BoxBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :description, :qr_token, :created_at, :updated_at

  field :qr_code_url do |box, options|
    box.qr_code_image.attached? ? options[:url_helpers].rails_blob_url(box.qr_code_image) : nil
  end

  view :with_items do
    association :items, blueprint: ItemBlueprint, view: :with_tags
  end
end
