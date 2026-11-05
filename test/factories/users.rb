FactoryBot.define do
  factory :user do
    account
    identity

    trait :system do
      role { :system }
      identity { nil }
    end

    trait :deactivated do
      after(:create) { |user| user.deactivate }
    end
  end
end
