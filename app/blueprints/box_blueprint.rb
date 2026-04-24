class BoxBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :description, :qr_token, :created_at, :updated_at

  field :qr_code_url do |box|
    if box.qr_code_image.attached?
      host = ENV.fetch('APP_BASE_URL', 'http://localhost:3000')
      Rails.application.routes.url_helpers.rails_blob_url(
        box.qr_code_image,
        host: host
      )
    end
  end

  view :with_items do
    association :items, blueprint: ItemBlueprint, view: :with_tags
  end
end
