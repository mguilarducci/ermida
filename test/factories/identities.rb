FactoryBot.define do
  factory :identity do
    sequence(:email_address) { |n| "person#{n}@example.com" }
    sequence(:name) { |n| "Person #{n}" }
  end
end
