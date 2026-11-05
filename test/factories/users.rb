FactoryBot.define do
  factory :user do
    account
    identity

    trait :system do
      role { :system }
      identity { nil }
    end

    # Goes through deactivate, so the factory never builds an inactive user that keeps its identity.
    trait :deactivated do
      after(:create) { |user| user.deactivate }
    end
  end
end
