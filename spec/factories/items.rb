FactoryBot.define do
  factory :item do
    box
    name        { Faker::Commerce.unique.product_name }
    description { Faker::Lorem.sentence }
  end
end
