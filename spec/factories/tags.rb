FactoryBot.define do
  factory :tag do
    space
    name { Faker::Lorem.unique.word }
  end
end
