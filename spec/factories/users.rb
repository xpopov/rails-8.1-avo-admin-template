FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { "Test User" }
    password { "correct-horse-battery-staple" }
    status { :verified }
    admin { false }

    trait :admin do
      admin { true }
    end

    trait :unverified do
      status { :unverified }
    end

    trait :closed do
      status { :closed }
    end
  end
end
