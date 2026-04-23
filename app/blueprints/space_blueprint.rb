class SpaceBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :description, :created_at

  view :with_boxes do
    association :boxes, blueprint: BoxBlueprint
  end
end
