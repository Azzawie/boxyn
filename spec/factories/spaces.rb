FactoryBot.define do
  factory :space do
    name        { Faker::Lorem.unique.word.capitalize }
    description { Faker::Lorem.sentence }
  end
end
