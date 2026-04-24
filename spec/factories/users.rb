FactoryBot.define do
  factory :user do
    email    { Faker::Internet.unique.email }
    password { 'password123' }

    # Skip the after_create personal space callback when you need
    # a bare user — use trait :with_personal_space (default) or :bare
    trait :bare do
      after(:build) { |u| u.class.skip_callback(:create, :after, :create_personal_space) }
      after(:create) { |u| u.class.set_callback(:create, :after, :create_personal_space) }
    end
  end
end
