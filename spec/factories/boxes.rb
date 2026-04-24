FactoryBot.define do
  factory :box do
    space
    name        { Faker::Lorem.unique.words(number: 2).join(' ').titleize }
    description { Faker::Lorem.sentence }
  end
end
