FactoryBot.define do
  factory :space_membership do
    association :user
    association :space
    role { :member }

    trait :owner do
      role { :owner }
    end

    trait :admin do
      role { :admin }
    end

    trait :member do
      role { :member }
    end
  end
end
