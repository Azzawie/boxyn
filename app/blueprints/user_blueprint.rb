class UserBlueprint < Blueprinter::Base
  identifier :id

  fields :email, :provider, :created_at
end
